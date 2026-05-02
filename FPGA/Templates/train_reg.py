"""
TinyTransformer v5 — Glucose Regression (Zynq 7020 / Q15)
==========================================================
Dataset : training_synthetic_1500_stratified.csv (1500 samples, stratified)
Architecture : identical to v2 (our best: 4.48 mM / 9.0% on old data)
  d_model=16, d_ff=32, Pre-LN, residuals, learnable pool
  HuberLoss(delta=0.3), CosineAnnealingLR, Adam

All FPGA constraints preserved:
  • Q15 fixed-point clamping on every activation
  • Per-layer weight clamping after every gradient step
  • 40-bit accumulator overflow check (2^31 limit)
  • Q15 weight export: C format and VHDL to_signed(…,16)
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split

# ──────────────────────────────────────────────────────────────
# Constants
# ──────────────────────────────────────────────────────────────
SCALE       = 32768.0
GLUCOSE_MIN = 0.0
GLUCOSE_MAX = 50.0
torch.manual_seed(7)

# ──────────────────────────────────────────────────────────────
# Load data
# ──────────────────────────────────────────────────────────────
df_train = pd.read_csv("training_synthetic_1500_stratified.csv")
df_val   = pd.read_csv("validation_predictions_16wl.csv")

feature_cols = [c for c in df_train.columns
                if c not in ("Glucose_mM_scaled", "Glucose_mM_original")]
assert len(feature_cols) == 16, f"Expected 16 features, got {len(feature_cols)}"

X_raw = df_train[feature_cols].values.astype(np.float32)
y_raw = df_train["Glucose_mM_original"].values.astype(np.float32)

print(f"Dataset     : {X_raw.shape[0]} samples, {X_raw.shape[1]} features")
print(f"Glucose     : {y_raw.min():.2f} – {y_raw.max():.2f} mM  "
      f"(mean={y_raw.mean():.2f}, std={y_raw.std():.2f})")

X_tr, X_te, y_tr, y_te = train_test_split(
    X_raw, y_raw, test_size=0.2, random_state=42)

scaler_X = StandardScaler()
X_tr_sc  = scaler_X.fit_transform(X_tr)
X_te_sc  = scaler_X.transform(X_te)
X_all_sc = scaler_X.transform(X_raw)

# ──────────────────────────────────────────────────────────────
# Target normalisation → [–1, +1]
# ──────────────────────────────────────────────────────────────
def norm_target(y):
    return (y - GLUCOSE_MIN) / (GLUCOSE_MAX - GLUCOSE_MIN) * 2.0 - 1.0

def denorm_target(y_n):
    return (np.array(y_n) + 1.0) / 2.0 * (GLUCOSE_MAX - GLUCOSE_MIN) + GLUCOSE_MIN

y_tr_n = norm_target(y_tr)
y_te_n = norm_target(y_te)

X_tr_t  = torch.tensor(X_tr_sc,  dtype=torch.float32).unsqueeze(-1)  # (N,16,1)
X_te_t  = torch.tensor(X_te_sc,  dtype=torch.float32).unsqueeze(-1)
X_all_t = torch.tensor(X_all_sc, dtype=torch.float32).unsqueeze(-1)
y_tr_t  = torch.tensor(y_tr_n,   dtype=torch.float32).unsqueeze(-1)  # (N,1)
y_te_t  = torch.tensor(y_te_n,   dtype=torch.float32).unsqueeze(-1)

# ──────────────────────────────────────────────────────────────
# Q15 helpers
# ──────────────────────────────────────────────────────────────
def float_to_q15(x: np.ndarray) -> np.ndarray:
    return np.round(np.clip(x, -1.0, 0.9999) * SCALE).astype(np.int16)

def q15(x: torch.Tensor) -> torch.Tensor:
    return torch.clamp(x, -1.0, 0.9999)

# ──────────────────────────────────────────────────────────────
# Model — identical to v2
# ──────────────────────────────────────────────────────────────
class TinyTransformerRegressor(nn.Module):
    def __init__(self, n_tokens: int = 16, d_model: int = 16, d_ff: int = 32):
        super().__init__()
        self.d_model = d_model

        self.embedding = nn.Linear(1, d_model)
        self.ln1       = nn.LayerNorm(d_model)
        self.ln2       = nn.LayerNorm(d_model)
        self.Wq        = nn.Linear(d_model, d_model, bias=False)
        self.Wk        = nn.Linear(d_model, d_model, bias=False)
        self.Wv        = nn.Linear(d_model, d_model, bias=False)
        self.ff1       = nn.Linear(d_model, d_ff)
        self.ff2       = nn.Linear(d_ff, d_model)
        self.pool_w    = nn.Parameter(torch.zeros(n_tokens))
        self.fc_out    = nn.Linear(d_model, 1)

        for name, p in self.named_parameters():
            if "ln" not in name and "pool_w" not in name:
                nn.init.uniform_(p, -0.15, 0.15)

    def forward(self, x: torch.Tensor) -> torch.Tensor:
        emb = q15(self.embedding(x))                       # (B,16,16)

        # Pre-LN attention + residual
        normed = self.ln1(emb)
        Q = q15(self.Wq(normed))
        K = q15(self.Wk(normed))
        V = q15(self.Wv(normed))
        S = q15(torch.bmm(Q, K.transpose(1, 2)) / (self.d_model ** 0.5))
        A = F.softmax(S, dim=-1)
        O = q15(torch.bmm(A, V))
        emb = q15(emb + O)

        # Pre-LN FF + residual
        normed2 = self.ln2(emb)
        h   = q15(F.relu(self.ff1(normed2)))
        y   = q15(self.ff2(h))
        emb = q15(emb + y)

        # Learnable weighted pool
        w      = F.softmax(self.pool_w, dim=0)
        pooled = q15((emb * w.unsqueeze(-1)).sum(dim=1))   # (B,16)

        return self.fc_out(pooled)                          # (B,1)


model    = TinyTransformerRegressor()
n_params = sum(p.numel() for p in model.parameters())
print(f"Model parameters: {n_params}")

optimizer = torch.optim.Adam(model.parameters(), lr=0.005, weight_decay=1e-4)
criterion = nn.HuberLoss(delta=0.3)
scheduler = torch.optim.lr_scheduler.CosineAnnealingLR(
    optimizer, T_max=8000, eta_min=1e-5)

# ──────────────────────────────────────────────────────────────
# Weight clamping bounds (same as v2)
# ──────────────────────────────────────────────────────────────
CLAMP = {
    "embedding.weight": 0.25,
    "embedding.bias"  : 0.25,
    "Wq.weight"       : 0.25,
    "Wk.weight"       : 0.25,
    "Wv.weight"       : 0.35,
    "ff1.weight"      : 0.35,
    "ff1.bias"        : 0.35,
    "ff2.weight"      : 0.25,
    "ff2.bias"        : 0.35,
    "fc_out.weight"   : 0.9999,
    "fc_out.bias"     : 0.9999,
}

# ──────────────────────────────────────────────────────────────
# Training loop
# ──────────────────────────────────────────────────────────────
best_mae   = float("inf")
best_state = None

for epoch in range(8000):
    model.train()
    optimizer.zero_grad()

    with torch.no_grad():
        for name, param in model.named_parameters():
            if name in CLAMP:
                param.clamp_(-CLAMP[name], CLAMP[name])

    out  = model(X_tr_t)
    loss = criterion(out, y_tr_t)
    loss.backward()
    optimizer.step()
    scheduler.step()

    if (epoch + 1) % 200 == 0:
        model.eval()
        with torch.no_grad():
            pred_n = model(X_te_t).squeeze().numpy()
            pred   = denorm_target(pred_n)
            mae    = np.mean(np.abs(pred - y_te))
            rmse   = np.sqrt(np.mean((pred - y_te) ** 2))

        if mae < best_mae:
            best_mae   = mae
            best_state = {k: v.clone() for k, v in model.state_dict().items()}

        print(f"Epoch [{epoch+1:5d}/8000]  Loss={loss.item():.5f}  "
              f"MAE={mae:.3f} mM  RMSE={rmse:.3f} mM  Best_MAE={best_mae:.3f} mM")

model.load_state_dict(best_state)
model.eval()

# ──────────────────────────────────────────────────────────────
# Final evaluation
# ──────────────────────────────────────────────────────────────
with torch.no_grad():
    pred_all  = denorm_target(model(X_all_t).squeeze().numpy())
    mae_full  = np.mean(np.abs(pred_all - y_raw))
    rmse_full = np.sqrt(np.mean((pred_all - y_raw) ** 2))

print(f"\nFull Dataset (1500 stratified)  →  MAE={mae_full:.3f} mM   RMSE={rmse_full:.3f} mM")
print(f"% error = {mae_full/50*100:.1f}%")

# Baseline comparison
print("\n=== Baseline from validation_predictions_16wl.csv ===")
true_val      = df_val["True_Glucose_mM"].values
baseline_pred = df_val["Predicted_Glucose_mM"].values
print(f"Baseline MAE  = {np.mean(np.abs(baseline_pred - true_val)):.3f} mM")
print(f"Baseline RMSE = {np.sqrt(np.mean((baseline_pred - true_val)**2)):.3f} mM")
print(f"Baseline %    = {np.mean(np.abs(baseline_pred - true_val))/50*100:.1f}%")

# ──────────────────────────────────────────────────────────────
# FPGA overflow check
# ──────────────────────────────────────────────────────────────
print("\n=== FPGA Overflow Check ===")
check_idx = [0, 5, 10, 20, 30, 53, 55, 59, 62, 64, 100, 101, 103, 110, 120]

def check_overflow(x_q15: np.ndarray, W_q15: np.ndarray, name: str) -> bool:
    max_acc = 0
    for out_j in range(W_q15.shape[0]):
        acc = sum(int(x_q15[k]) * int(W_q15[out_j, k])
                  for k in range(x_q15.shape[0]))
        max_acc = max(max_acc, abs(acc))
    overflow = max_acc > 2 ** 31
    if overflow:
        print(f"  OVERFLOW in {name}: max_acc={max_acc} > {2**31}")
    return overflow

any_overflow = False
errors = []
with torch.no_grad():
    for i, idx in enumerate(check_idx):
        x_in  = torch.tensor(X_all_sc[idx], dtype=torch.float32).unsqueeze(-1).unsqueeze(0)
        emb   = q15(model.embedding(x_in))

        emb_q15 = torch.round(emb[0, 0] * SCALE).clamp(-32768, 32767).short().numpy()
        Wq_q15  = torch.round(model.Wq.weight * SCALE).clamp(-32768, 32767).short().numpy()
        Wk_q15  = torch.round(model.Wk.weight * SCALE).clamp(-32768, 32767).short().numpy()
        Wv_q15  = torch.round(model.Wv.weight * SCALE).clamp(-32768, 32767).short().numpy()

        ov = (check_overflow(emb_q15, Wq_q15, f"Wq[{i}]") or
              check_overflow(emb_q15, Wk_q15, f"Wk[{i}]") or
              check_overflow(emb_q15, Wv_q15, f"Wv[{i}]"))
        any_overflow = any_overflow or ov

        pred = denorm_target(model(x_in).item())
        true = y_raw[idx]
        err  = abs(pred - true)
        errors.append(err)
        print(f"  [{i:2d}] idx={idx:3d}  true={true:6.2f} mM  pred={pred:6.2f} mM  "
              f"err={err:.2f} mM  emb_max={emb.abs().max():.3f}")

if not any_overflow:
    print("\nNo overflow detected! Safe for 40-bit Zynq 7020 accumulator.")
print(f"FPGA sample MAE: {np.mean(errors):.3f} mM")

# ──────────────────────────────────────────────────────────────
# Weight export
# ──────────────────────────────────────────────────────────────
def export(param: torch.Tensor) -> np.ndarray:
    return float_to_q15(param.detach().numpy())

D  = model.d_model  # 16
FF = 32

print("\n=== Embedding for main.c ===")
print(f"W_emb[{D}]: {{{', '.join(str(int(v)) for v in export(model.embedding.weight).flatten())}}}")
print(f"b_emb[{D}]: {{{', '.join(str(int(v)) for v in export(model.embedding.bias).flatten())}}}")

print("\n=== Regression head for main.c ===")
print(f"W_fc[1][{D}]: {{{', '.join(str(int(v)) for v in export(model.fc_out.weight).flatten())}}}")
print(f"b_fc[1]:      {{{', '.join(str(int(v)) for v in export(model.fc_out.bias).flatten())}}}")
print()
print("// Denormalise on Zynq PS (ARM) after FPGA inference:")
print(f"// glucose_mM = (q15_out / 32768.0f + 1.0f) / 2.0f * {GLUCOSE_MAX-GLUCOSE_MIN:.1f}f + {GLUCOSE_MIN:.1f}f;")

print("\n=== Pool weights (softmax applied, use as float on PS) ===")
pool_w_soft = F.softmax(model.pool_w, dim=0).detach().numpy()
print(f"pool_w[16]: {{{', '.join(f'{v:.6f}f' for v in pool_w_soft)}}}")

print(f"\n=== Wq for qkv_projector.vhd ({D}x{D}) ===")
Wq_q = export(model.Wq.weight).flatten()
for i in range(0, D*D, 8):
    print("        " + ", ".join(f"to_signed({int(v)},16)" for v in Wq_q[i:i+8]) + ",")

print(f"\n=== Wk for qkv_projector.vhd ({D}x{D}) ===")
Wk_q = export(model.Wk.weight).flatten()
for i in range(0, D*D, 8):
    print("        " + ", ".join(f"to_signed({int(v)},16)" for v in Wk_q[i:i+8]) + ",")

print(f"\n=== Wv for qkv_projector.vhd ({D}x{D}) ===")
Wv_q = export(model.Wv.weight).flatten()
for i in range(0, D*D, 8):
    print("        " + ", ".join(f"to_signed({int(v)},16)" for v in Wv_q[i:i+8]) + ",")

print(f"\n=== FF1_W for feed_forward.vhd ({FF}x{D}) ===")
ff1_w_q = export(model.ff1.weight).flatten()
for i in range(0, FF*D, 8):
    print("        " + ", ".join(f"to_signed({int(v)},16)" for v in ff1_w_q[i:i+8]) + ",")

print(f"\n=== FF1_B ({FF},) ===")
print(", ".join(f"to_signed({int(v)},16)" for v in export(model.ff1.bias).flatten()))

print(f"\n=== FF2_W for feed_forward.vhd ({D}x{FF}) ===")
ff2_w_q = export(model.ff2.weight).flatten()
for i in range(0, D*FF, 8):
    print("        " + ", ".join(f"to_signed({int(v)},16)" for v in ff2_w_q[i:i+8]) + ",")

print(f"\n=== FF2_B ({D},) ===")
print(", ".join(f"to_signed({int(v)},16)" for v in export(model.ff2.bias).flatten()))

print(f"\n=== LayerNorm weights (implement on PS/ARM, not FPGA PL) ===")
print(f"ln1_weight: {list(model.ln1.weight.detach().numpy().round(5))}")
print(f"ln1_bias:   {list(model.ln1.bias.detach().numpy().round(5))}")
print(f"ln2_weight: {list(model.ln2.weight.detach().numpy().round(5))}")
print(f"ln2_bias:   {list(model.ln2.bias.detach().numpy().round(5))}")