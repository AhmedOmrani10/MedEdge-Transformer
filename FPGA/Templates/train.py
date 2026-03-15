import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from sklearn import datasets
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

# ==========================================================
# 1. Hyperparameters (MATCHES FPGA ARCHITECTURE)
# ==========================================================

seq_len = 4        # 4 features treated as sequence
d_model = 8        # embedding dimension
d_ff = 16          # feed forward hidden size
num_classes = 3
epochs = 1000
lr = 0.01

# ==========================================================
# 2. Load Iris Dataset
# ==========================================================

iris = datasets.load_iris()
X = iris.data
y = iris.target

scaler = StandardScaler()
X = scaler.fit_transform(X)

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

X_train = torch.tensor(X_train, dtype=torch.float32)
X_test = torch.tensor(X_test, dtype=torch.float32)
y_train = torch.tensor(y_train, dtype=torch.long)
y_test = torch.tensor(y_test, dtype=torch.long)

# reshape to (batch, seq_len, 1)
X_train = X_train.unsqueeze(-1)
X_test = X_test.unsqueeze(-1)

# ==========================================================
# 3. Tiny Transformer (Hardware Friendly)
# ==========================================================

class TinyTransformer(nn.Module):
    def __init__(self):
        super().__init__()

        # 1) Embedding (1 → 8)
        self.embedding = nn.Linear(1, d_model)

        # 2) Attention (single head)
        self.Wq = nn.Linear(d_model, d_model, bias=False)
        self.Wk = nn.Linear(d_model, d_model, bias=False)
        self.Wv = nn.Linear(d_model, d_model, bias=False)

        # 3) Feed Forward
        self.ff1 = nn.Linear(d_model, d_ff)
        self.ff2 = nn.Linear(d_ff, d_model)

        # 4) Final classifier
        self.fc_out = nn.Linear(d_model, num_classes)

    def forward(self, x):
        # x: (batch, 4, 1)

        x = self.embedding(x)          # (batch, 4, 8)

        Q = self.Wq(x)
        K = self.Wk(x)
        V = self.Wv(x)

        # Attention score
        scores = torch.matmul(Q, K.transpose(-2, -1))
        scores = scores / np.sqrt(d_model)

        attn = F.softmax(scores, dim=-1)
        x = torch.matmul(attn, V)

        # Feed Forward
        x = F.relu(self.ff1(x))
        x = self.ff2(x)

        # Global average pooling
        x = torch.mean(x, dim=1)

        out = self.fc_out(x)

        return out


# ==========================================================
# 4. Training
# ==========================================================

model = TinyTransformer()
optimizer = torch.optim.Adam(model.parameters(), lr=lr)
criterion = nn.CrossEntropyLoss()

for epoch in range(epochs):
    model.train()
    optimizer.zero_grad()

    outputs = model(X_train)
    loss = criterion(outputs, y_train)

    loss.backward()
    optimizer.step()

    if (epoch+1) % 50 == 0:
        print(f"Epoch [{epoch+1}/{epochs}] Loss: {loss.item():.4f}")

# ==========================================================
# 5. Evaluation
# ==========================================================

model.eval()
with torch.no_grad():
    outputs = model(X_test)
    _, predicted = torch.max(outputs, 1)
    accuracy = (predicted == y_test).float().mean()

print("Test Accuracy:", accuracy.item())

# ==========================================================
# 6. Q1.15 Quantization
# ==========================================================

def float_to_q15(x):
    x = np.clip(x, -1.0, 0.9999)
    return np.round(x * 32768).astype(np.int16)

quantized_weights = {}

for name, param in model.named_parameters():
    if param.requires_grad:
        weights = param.detach().numpy()
        q_weights = float_to_q15(weights)
        quantized_weights[name] = q_weights
        print(f"{name} quantized. Shape: {q_weights.shape}")

# ==========================================================
# 7. Export Weights to VHDL File
# ==========================================================

def export_to_vhdl(weights_dict, filename="weights.vhd"):
    with open(filename, "w") as f:
        f.write("library IEEE;\n")
        f.write("use IEEE.STD_LOGIC_1164.ALL;\n")
        f.write("use IEEE.NUMERIC_STD.ALL;\n\n")

        for name, weights in weights_dict.items():
            flat = weights.flatten()
            f.write(f"-- {name}\n")
            f.write(f"type {name.replace('.', '_')}_array is array (0 to {len(flat)-1}) of signed(15 downto 0);\n")
            f.write(f"constant {name.replace('.', '_')} : {name.replace('.', '_')}_array := (\n")

            for i, val in enumerate(flat):
                f.write(f"    to_signed({int(val)}, 16)")
                if i != len(flat)-1:
                    f.write(",\n")
                else:
                    f.write("\n")

            f.write(");\n\n")

export_to_vhdl(quantized_weights)

print("VHDL weight file generated successfully.")
# ==========================================================
# 8. Save Trained Model
# ==========================================================

torch.save(model.state_dict(), "tiny_transformer.pth")
print("Model saved as tiny_transformer.pth")


# ==========================================================
# 9. Simple Console Test Application
# ==========================================================

class_names = iris.target_names  # ['setosa', 'versicolor', 'virginica']

def predict_sample(sample):
    model.eval()
    sample = np.array(sample).reshape(1, 4)
    sample = scaler.transform(sample)
    sample = torch.tensor(sample, dtype=torch.float32).unsqueeze(-1)

    with torch.no_grad():
        output = model(sample)
        probs = F.softmax(output, dim=1)
        predicted_class = torch.argmax(probs, dim=1).item()

    return predicted_class, probs.numpy()


def quantized_inference(sample):
    """
    Simulates Q1.15 inference (very important for FPGA validation)
    """
    sample = np.array(sample).reshape(1, 4)
    sample = scaler.transform(sample)
    sample = torch.tensor(sample, dtype=torch.float32).unsqueeze(-1)

    with torch.no_grad():
        output = model(sample)
        output_np = output.numpy()

    # Quantize output logits
    q_output = float_to_q15(output_np)
    predicted_class = np.argmax(q_output)

    return predicted_class, q_output


def run_application():
    while True:
        print("\n===== Tiny Transformer Iris Classifier =====")
        print("1 - Manual input")
        print("2 - Random test sample")
        print("3 - Exit")

        choice = input("Choose option: ")

        if choice == "1":
            print("\nEnter Iris features:")
            sl = float(input("Sepal length: "))
            sw = float(input("Sepal width: "))
            pl = float(input("Petal length: "))
            pw = float(input("Petal width: "))

            sample = [sl, sw, pl, pw]

            pred, probs = predict_sample(sample)
            q_pred, q_out = quantized_inference(sample)

            print("\n--- FLOAT INFERENCE ---")
            print("Predicted class:", class_names[pred])
            print("Probabilities:", probs)

            print("\n--- Q15 SIMULATION ---")
            print("Predicted class:", class_names[q_pred])
            print("Quantized logits:", q_out)

        elif choice == "2":
            idx = np.random.randint(0, len(X_test))
            sample = X_test[idx].squeeze().numpy()

            # Undo scaling for display
            sample_display = scaler.inverse_transform(sample.reshape(1, -1))[0]

            print("\nRandom sample:", sample_display)
            print("True class:", class_names[y_test[idx]])

            pred, probs = predict_sample(sample_display)
            q_pred, q_out = quantized_inference(sample_display)

            print("\n--- FLOAT INFERENCE ---")
            print("Predicted class:", class_names[pred])
            print("Probabilities:", probs)

            print("\n--- Q15 SIMULATION ---")
            print("Predicted class:", class_names[q_pred])
            print("Quantized logits:", q_out)

        elif choice == "3":
            break
        else:
            print("Invalid choice.")


# ==========================================================
# 10. Run App
# ==========================================================

run_application()