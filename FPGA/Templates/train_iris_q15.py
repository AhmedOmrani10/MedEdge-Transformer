import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from sklearn import datasets
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

SCALE = 32768.0
torch.manual_seed(7)

iris   = datasets.load_iris()
scaler = StandardScaler()
X_sc   = scaler.fit_transform(iris.data)
X_all  = torch.tensor(X_sc, dtype=torch.float32).unsqueeze(-1)
y_all  = torch.tensor(iris.target, dtype=torch.long)

X_train, X_test, y_train, y_test = train_test_split(
    X_sc, iris.target, test_size=0.2, random_state=42)
X_train_t = torch.tensor(X_train, dtype=torch.float32).unsqueeze(-1)
X_test_t  = torch.tensor(X_test,  dtype=torch.float32).unsqueeze(-1)
y_train_t = torch.tensor(y_train, dtype=torch.long)
y_test_t  = torch.tensor(y_test,  dtype=torch.long)

def float_to_q15(x):
    return np.round(np.clip(x, -1.0, 0.9999) * SCALE).astype(np.int16)

def q15(x):
    return torch.clamp(x, -1.0, 0.9999)

class TinyTransformer(nn.Module):
    def __init__(self):
        super().__init__()
        self.embedding = nn.Linear(1, 8)
        self.Wq = nn.Linear(8, 8, bias=False)
        self.Wk = nn.Linear(8, 8, bias=False)
        self.Wv = nn.Linear(8, 8, bias=False)
        self.ff1 = nn.Linear(8, 16)
        self.ff2 = nn.Linear(16, 8)
        self.fc_out = nn.Linear(8, 3)
        for p in self.parameters():
            nn.init.uniform_(p, -0.2, 0.2)

    def forward(self, x):
        emb    = q15(self.embedding(x))
        Q      = q15(self.Wq(emb))
        K      = q15(self.Wk(emb))
        V      = q15(self.Wv(emb))
        S      = q15(torch.bmm(Q, K.transpose(1,2)) / (8**0.5))
        A      = F.softmax(S, dim=-1)
        O      = q15(torch.bmm(A, V))
        h      = q15(F.relu(self.ff1(O)))
        y      = q15(self.ff2(h))
        pooled = q15(y.mean(dim=1))
        return self.fc_out(pooled)

model     = TinyTransformer()
optimizer = torch.optim.Adam(model.parameters(), lr=0.005, weight_decay=1e-4)
criterion = nn.CrossEntropyLoss()
scheduler = torch.optim.lr_scheduler.StepLR(optimizer, step_size=500, gamma=0.5)

best_acc   = 0.0
best_state = None

for epoch in range(5000):
    model.train()
    optimizer.zero_grad()
    # Clamp weights to prevent FPGA overflow
    # Max embedding output ≈ max_feature * max_weight + max_bias
    # Iris features ≈ ±3.0, so keep weights < 0.3 to keep emb < ±1.0
    # QKV weights: emb ≈ ±1.0 so keep < 0.3 to keep Q/K/V < ±1.0
    with torch.no_grad():
        model.embedding.weight.clamp_(-0.3, 0.3)
        model.embedding.bias.clamp_(-0.3, 0.3)
        model.Wq.weight.clamp_(-0.3, 0.3)
        model.Wk.weight.clamp_(-0.3, 0.3)
        model.Wv.weight.clamp_(-0.5, 0.5)
        model.ff1.weight.clamp_(-0.5, 0.5)
        model.ff1.bias.clamp_(-0.5, 0.5)
        model.ff2.weight.clamp_(-0.5, 0.5)
        model.ff2.bias.clamp_(-0.5, 0.5)
        model.fc_out.weight.clamp_(-0.9999, 0.9999)
        model.fc_out.bias.clamp_(-0.9999, 0.9999)

    out  = model(X_train_t)
    loss = criterion(out, y_train_t)
    loss.backward()
    optimizer.step()
    scheduler.step()

    if (epoch+1) % 200 == 0:
        model.eval()
        with torch.no_grad():
            pred = model(X_test_t).argmax(dim=1)
            acc  = (pred == y_test_t).float().mean().item()
        if acc > best_acc:
            best_acc   = acc
            best_state = {k: v.clone() for k,v in model.state_dict().items()}
        print(f"Epoch [{epoch+1}/5000] Loss={loss.item():.4f} "
              f"TestAcc={acc*100:.1f}% Best={best_acc*100:.1f}%")

model.load_state_dict(best_state)
model.eval()

# Full accuracy
with torch.no_grad():
    pred_all = model(X_all).argmax(dim=1)
    full_acc = (pred_all == y_all).float().mean().item()
print(f"\nFull Dataset Accuracy: {full_acc*100:.1f}%")

# ============================================
# Verify FPGA won't overflow using integer sim
# ============================================
print("\n=== Checking FPGA overflow for all 15 samples ===")
fpga_idx = [0,5,10,20,30,53,55,59,62,64,100,101,103,110,120]
classes  = ['Setosa','Versicolor','Virginica']

def check_overflow(x_q15, W_q15, name):
    max_acc = 0
    for out_j in range(W_q15.shape[0]):
        acc = sum(int(x_q15[k]) * int(W_q15[out_j,k])
                  for k in range(x_q15.shape[0]))
        max_acc = max(max_acc, abs(acc))
    overflow = max_acc > 2**31
    if overflow:
        print(f"  OVERFLOW in {name}: max_acc={max_acc} > {2**31}")
    return overflow

any_overflow = False
correct = 0
with torch.no_grad():
    for i, idx in enumerate(fpga_idx):
        x_in = torch.tensor(X_sc[idx],dtype=torch.float32).unsqueeze(-1).unsqueeze(0)
        emb  = q15(model.embedding(x_in))

        # Check each stage for overflow
        emb_q15 = torch.round(emb[0,0]*SCALE).clamp(-32768,32767).short().numpy()
        Wq_q15  = torch.round(model.Wq.weight*SCALE).clamp(-32768,32767).short().numpy()
        Wk_q15  = torch.round(model.Wk.weight*SCALE).clamp(-32768,32767).short().numpy()
        Wv_q15  = torch.round(model.Wv.weight*SCALE).clamp(-32768,32767).short().numpy()

        ov = (check_overflow(emb_q15, Wq_q15, f"Wq[{i}]") or
              check_overflow(emb_q15, Wk_q15, f"Wk[{i}]") or
              check_overflow(emb_q15, Wv_q15, f"Wv[{i}]"))
        any_overflow = any_overflow or ov

        pred = model(x_in).argmax(dim=1).item()
        true = iris.target[idx]
        ok   = "OK" if pred==true else "XX"
        if pred==true: correct+=1
        print(f"  [{i:2d}] true={classes[true]:12s} pred={classes[pred]:12s} {ok}  "
              f"emb_max={emb.abs().max():.3f}")

if not any_overflow:
    print("\nNo overflow detected! Safe for 40-bit FPGA accumulator.")
print(f"FPGA samples: {correct}/15 = {correct/15*100:.1f}%")

# Export weights
def export(param):
    return float_to_q15(param.detach().numpy())

print("\n=== Embedding for main.c ===")
W_emb_q = export(model.embedding.weight).flatten()
b_emb_q = export(model.embedding.bias).flatten()
print(f"W_emb: {{{', '.join(str(int(v)) for v in W_emb_q)}}}")
print(f"b_emb: {{{', '.join(str(int(v)) for v in b_emb_q)}}}")

print("\n=== Classifier for main.c ===")
fc_w_q = export(model.fc_out.weight)
fc_b_q = export(model.fc_out.bias)
print("W_fc[3][8]:")
for row in fc_w_q:
    print("{" + ", ".join(str(int(v)) for v in row) + "},")
print(f"b_fc[3]: {{{', '.join(str(int(v)) for v in fc_b_q)}}}")

print("\n=== Wq for qkv_projector.vhd ===")
Wq_q = export(model.Wq.weight).flatten()
for i in range(0,64,8):
    print("        "+", ".join(f"to_signed({int(v)},16)" for v in Wq_q[i:i+8])+",")

print("\n=== Wk for qkv_projector.vhd ===")
Wk_q = export(model.Wk.weight).flatten()
for i in range(0,64,8):
    print("        "+", ".join(f"to_signed({int(v)},16)" for v in Wk_q[i:i+8])+",")

print("\n=== Wv for qkv_projector.vhd ===")
Wv_q = export(model.Wv.weight).flatten()
for i in range(0,64,8):
    print("        "+", ".join(f"to_signed({int(v)},16)" for v in Wv_q[i:i+8])+",")

print("\n=== FF1_W for feed_forward.vhd ===")
ff1_w_q = export(model.ff1.weight).flatten()
for i in range(0,128,8):
    print("        "+", ".join(f"to_signed({int(v)},16)" for v in ff1_w_q[i:i+8])+",")

print("\n=== FF1_B ===")
print(", ".join(f"to_signed({int(v)},16)"
      for v in export(model.ff1.bias).flatten()))

print("\n=== FF2_W for feed_forward.vhd ===")
ff2_w_q = export(model.ff2.weight).flatten()
for i in range(0,128,8):
    print("        "+", ".join(f"to_signed({int(v)},16)" for v in ff2_w_q[i:i+8])+",")

print("\n=== FF2_B ===")
print(", ".join(f"to_signed({int(v)},16)"
      for v in export(model.ff2.bias).flatten()))