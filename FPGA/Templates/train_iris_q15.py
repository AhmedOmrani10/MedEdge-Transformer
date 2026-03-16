import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from sklearn import datasets
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# ==========================================================
# 1. Hyperparameters
# ==========================================================
seq_len    = 4
d_model    = 8
d_ff       = 16
num_classes = 3
epochs     = 3000
lr         = 0.005

# ==========================================================
# 2. Load Iris Dataset
# ==========================================================
iris   = datasets.load_iris()
X      = iris.data
y      = iris.target

scaler = StandardScaler()
X      = scaler.fit_transform(X)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

X_train = torch.tensor(X_train, dtype=torch.float32).unsqueeze(-1)
X_test  = torch.tensor(X_test,  dtype=torch.float32).unsqueeze(-1)
y_train = torch.tensor(y_train, dtype=torch.long)
y_test  = torch.tensor(y_test,  dtype=torch.long)

# ==========================================================
# 3. Q1.15 Quantization Helpers
# ==========================================================
SCALE = 32768.0

def float_to_q15(x):
    x = np.clip(x, -1.0, 0.9999)
    return np.round(x * SCALE).astype(np.int16)

def q15_clamp(x):
    """Clamp tensor to Q1.15 range [-1.0, 1.0) during forward pass"""
    return torch.clamp(x, -1.0, 0.9999)

# ==========================================================
# 4. Tiny Transformer with Quantization-Aware Training
# ==========================================================
class TinyTransformerQAT(nn.Module):
    def __init__(self):
        super().__init__()
        self.embedding = nn.Linear(1, d_model)
        self.Wq = nn.Linear(d_model, d_model, bias=False)
        self.Wk = nn.Linear(d_model, d_model, bias=False)
        self.Wv = nn.Linear(d_model, d_model, bias=False)
        self.ff1 = nn.Linear(d_model, d_ff)
        self.ff2 = nn.Linear(d_ff, d_model)
        self.fc_out = nn.Linear(d_model, num_classes)

        # Initialize weights small so they stay in Q1.15 range
        for name, param in self.named_parameters():
            nn.init.uniform_(param, -0.5, 0.5)

    def forward(self, x, quantize=False):
        # x: (batch, 4, 1)

        # --- Embedding ---
        x = self.embedding(x)           # (batch, 4, 8)
        x = q15_clamp(x)                # clamp to Q1.15

        # --- QKV ---
        Q = q15_clamp(self.Wq(x))
        K = q15_clamp(self.Wk(x))
        V = q15_clamp(self.Wv(x))

        # --- Attention Score ---
        scores = torch.matmul(Q, K.transpose(-2, -1)) / np.sqrt(d_model)
        scores = q15_clamp(scores)       # clamp S matrix

        attn = F.softmax(scores, dim=-1) # softmax stays in [0,1] — OK
        x    = torch.matmul(attn, V)     # (batch, 4, 8)
        x    = q15_clamp(x)             # clamp O matrix

        # --- Feed Forward ---
        x = self.ff1(x)                  # (batch, 4, 16)
        x = F.relu(x)
        x = q15_clamp(x)                # clamp FF1 hidden

        x = self.ff2(x)                  # (batch, 4, 8)
        x = q15_clamp(x)                # clamp FF2 output

        # --- AvgPool ---
        x = torch.mean(x, dim=1)        # (batch, 8)
        x = q15_clamp(x)                # clamp pooled

        # --- Classifier ---
        out = self.fc_out(x)
        return out

# ==========================================================
# 5. Training
# ==========================================================
model     = TinyTransformerQAT()
optimizer = torch.optim.Adam(model.parameters(), lr=lr, weight_decay=1e-4)
criterion = nn.CrossEntropyLoss()
scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=500, gamma=0.5)

best_acc  = 0.0
best_state = None

for epoch in range(epochs):
    model.train()
    optimizer.zero_grad()

    # Clamp weights to Q1.15 range before forward pass
    with torch.no_grad():
        for param in model.parameters():
            param.clamp_(-0.9999, 0.9999)

    outputs = model(X_train)
    loss    = criterion(outputs, y_train)
    loss.backward()
    optimizer.step()
    scheduler.step()

    if (epoch + 1) % 100 == 0:
        model.eval()
        with torch.no_grad():
            test_out  = model(X_test)
            _, pred   = torch.max(test_out, 1)
            acc       = (pred == y_test).float().mean().item()
        if acc > best_acc:
            best_acc   = acc
            best_state = {k: v.clone() for k, v in model.state_dict().items()}
        print(f"Epoch [{epoch+1}/{epochs}]  "
              f"Loss: {loss.item():.4f}  "
              f"Test Acc: {acc*100:.1f}%  "
              f"Best: {best_acc*100:.1f}%")

# Load best model
model.load_state_dict(best_state)
model.eval()

# ==========================================================
# 6. Final Evaluation
# ==========================================================
with torch.no_grad():
    outputs   = model(X_test)
    _, pred   = torch.max(outputs, 1)
    final_acc = (pred == y_test).float().mean().item()
print(f"\nFinal Test Accuracy: {final_acc*100:.1f}%")

# Full dataset accuracy
X_all = torch.tensor(
    scaler.transform(iris.data), dtype=torch.float32
).unsqueeze(-1)
y_all = torch.tensor(iris.target, dtype=torch.long)

with torch.no_grad():
    out_all  = model(X_all)
    _, p_all = torch.max(out_all, 1)
    full_acc = (p_all == y_all).float().mean().item()
print(f"Full Dataset Accuracy (150 samples): {full_acc*100:.1f}%")

# ==========================================================
# 7. Verify ALL intermediate values stay in Q1.15 range
# ==========================================================
print("\n=== Verifying Q1.15 compliance ===")

sample_0 = X_all[0:1]  # first sample

with torch.no_grad():
    x = model.embedding(sample_0)
    x = q15_clamp(x)
    print(f"Embedding range:  [{x.min():.4f}, {x.max():.4f}]  "
          f"Q15: [{x.min()*SCALE:.0f}, {x.max()*SCALE:.0f}]")

    Q = q15_clamp(model.Wq(x))
    K = q15_clamp(model.Wk(x))
    V = q15_clamp(model.Wv(x))
    print(f"Q range:          [{Q.min():.4f}, {Q.max():.4f}]")
    print(f"K range:          [{K.min():.4f}, {K.max():.4f}]")
    print(f"V range:          [{V.min():.4f}, {V.max():.4f}]")

    scores = q15_clamp(torch.matmul(Q, K.transpose(-2,-1)) / np.sqrt(d_model))
    print(f"S range:          [{scores.min():.4f}, {scores.max():.4f}]")

    attn = F.softmax(scores, dim=-1)
    O    = q15_clamp(torch.matmul(attn, V))
    print(f"O range:          [{O.min():.4f}, {O.max():.4f}]")

    h = q15_clamp(F.relu(model.ff1(O)))
    print(f"FF1 hidden range: [{h.min():.4f}, {h.max():.4f}]")

    ff2 = q15_clamp(model.ff2(h))
    print(f"FF2 output range: [{ff2.min():.4f}, {ff2.max():.4f}]")

    pooled = q15_clamp(ff2.mean(dim=1))
    print(f"Pooled range:     [{pooled.min():.4f}, {pooled.max():.4f}]")

    print(f"\nPooled Q15 values (sample 0):")
    for i in range(8):
        val  = pooled[0,i].item()
        q15  = int(val * SCALE)
        flag = "OK" if abs(q15) <= 32767 else "OVERFLOW"
        print(f"  pooled[{i}] = {val:.4f}  Q15={q15}  {flag}")

# ==========================================================
# 8. Export Quantized Weights to VHDL
# ==========================================================
print("\n=== Exporting weights ===")

quantized_weights = {}
for name, param in model.named_parameters():
    weights    = param.detach().numpy()
    q_weights  = float_to_q15(weights)
    quantized_weights[name] = q_weights
    w_min = q_weights.min()
    w_max = q_weights.max()
    print(f"{name}: shape={q_weights.shape}  "
          f"range=[{w_min}, {w_max}]")

def export_to_vhdl(weights_dict, filename="weights_qat.vhd"):
    with open(filename, "w") as f:
        f.write("library IEEE;\n")
        f.write("use IEEE.STD_LOGIC_1164.ALL;\n")
        f.write("use IEEE.NUMERIC_STD.ALL;\n\n")
        for name, weights in weights_dict.items():
            flat = weights.flatten()
            safe = name.replace('.', '_')
            f.write(f"-- {name}\n")
            f.write(f"type {safe}_array is array "
                    f"(0 to {len(flat)-1}) of signed(15 downto 0);\n")
            f.write(f"constant {safe} : {safe}_array := (\n")
            for i, val in enumerate(flat):
                comma = "," if i != len(flat)-1 else ""
                f.write(f"    to_signed({int(val)}, 16){comma}\n")
            f.write(");\n\n")

export_to_vhdl(quantized_weights)
print("Weights exported to weights_qat.vhd")

# ==========================================================
# 9. Save Model
# ==========================================================
torch.save(model.state_dict(), "tiny_transformer_qat.pth")
print("Model saved as tiny_transformer_qat.pth")

# ==========================================================
# 10. Print weights for main.c (PS side)
# ==========================================================
print("\n=== PS-side weights for main.c ===")

# Embedding
w_emb = quantized_weights['embedding.weight'].flatten()
b_emb = quantized_weights['embedding.bias'].flatten()
print("\nW_emb:")
print("{" + ", ".join(str(int(v)) for v in w_emb) + "}")
print("b_emb:")
print("{" + ", ".join(str(int(v)) for v in b_emb) + "}")

# Classifier
w_fc = quantized_weights['fc_out.weight']
b_fc = quantized_weights['fc_out.bias']
print("\nW_fc[3][8]:")
for row in w_fc:
    print("{" + ", ".join(str(int(v)) for v in row) + "},")
print("b_fc[3]:")
print("{" + ", ".join(str(int(v)) for v in b_fc) + "}")

# ==========================================================
# 11. Test all 15 FPGA samples
# ==========================================================
print("\n=== Testing FPGA samples ===")

fpga_indices = [0, 5, 10, 20, 30,
                53, 55, 59, 62, 64,
                100, 101, 103, 110, 120]

X_raw   = iris.data
y_raw   = iris.target
X_sc    = scaler.transform(X_raw)
classes = ['Setosa', 'Versicolor', 'Virginica']

correct = 0
with torch.no_grad():
    for i, idx in enumerate(fpga_indices):
        x_in   = torch.tensor(
                     X_sc[idx], dtype=torch.float32
                 ).unsqueeze(-1).unsqueeze(0)
        out    = model(x_in)
        pred   = out.argmax(dim=1).item()
        true   = y_raw[idx]
        ok     = "OK" if pred == true else "XX"
        if pred == true:
            correct += 1
        print(f"  [{i:2d}] idx={idx:3d} "
              f"true={classes[true]:12s} "
              f"pred={classes[pred]:12s} {ok}")

print(f"\nFPGA samples: {correct}/15 = {correct/15*100:.1f}%")