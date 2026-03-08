import numpy as np

Q_row0 = np.array([0x046F, 0x0EE2, 0xE94A, 0xFA77,
                   0x1414, 0xFB07, 0x21C7, 0x0337])

# Convert signed hex to float
def to_float(x):
    if x > 32767:
        x -= 65536
    return x / 32768.0

Q = np.array([to_float(x) for x in Q_row0])
K = np.array([to_float(x) for x in
             [0xF70B, 0x0CE5, 0xF3BD, 0x0CD0,
              0x1321, 0xFE41, 0xFF7A, 0x0701]])

S00 = np.dot(Q, K) / np.sqrt(8)
print("S[0][0] =", S00)
print("In Q1.15 =", hex(int(S00 * 32768) & 0xFFFF))