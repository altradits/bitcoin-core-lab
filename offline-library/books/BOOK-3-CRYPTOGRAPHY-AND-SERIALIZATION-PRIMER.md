# Book 3: Cryptography, Elliptic Curves & Wire Serialization (From Memory)

> **Purpose of This Offline Book:**
> Covers the mathematical and byte-level foundations required for Stages `01`, `02`, `05`, `06`, `07`, and `08` (and chapters 1–7 of _Programming Bitcoin_ in `/Users/mac/bitcoin-references/books/programming-bitcoin/`). Read the equations, close the file, and complete the **Blind Recall Drills**.

---

## Chapter 1: Finite Fields $\mathbb{F}_p$ and `secp256k1`

Bitcoin's elliptic curve `secp256k1` is defined over the prime finite field $\mathbb{F}_p$ where:
$$p = 2^{256} - 2^{32} - 977$$

Every point $P = (x, y)$ on `secp256k1` satisfies:
$$y^2 \equiv x^3 + 7 \pmod p$$

The generator point $G$ generates a cyclic group of prime order $n$ (where $n < p$ is the number of points on the curve):
- **Private Key ($k$):** A 256-bit integer in $[1, n-1]$.
- **Public Key ($P$):** The elliptic curve point $P = k \cdot G$ obtained by adding $G$ to itself $k$ times using the chord-and-tangent group law.
- **Compressed Public Key (33 bytes):** `0x02` (if $y$ is even) or `0x03` (if $y$ is odd) followed by the 32-byte Big-Endian $x$-coordinate.
- **BIP340 X-Only Public Key (32 bytes, Taproot):** Only the 32-byte Big-Endian $x$-coordinate (implicitly assuming $y$ is even; if $y$ is odd, negate the private key $k \leftarrow n - k$).

---

## Chapter 2: ECDSA vs BIP340 Schnorr Signatures

### 2.1 Why BIP340 Schnorr Replaced ECDSA in Taproot (Stage 07)
Given private key $k$, public key $P = k \cdot G$, random nonce $r$, nonce point $R = r \cdot G$, and challenge hash $e = \text{TaggedHash}_{\text{BIP0340/challenge}}(R_x \parallel P_x \parallel m)$:

$$\text{Schnorr Signature } (R_x, s): \quad s \equiv r + e \cdot k \pmod n$$

**Verification Equation (Linear!):**
$$s \cdot G \stackrel{?}{=} R + e \cdot P$$

Because Schnorr verification is **linear** (no modular inverse $r^{-1} \bmod n$ like ECDSA):
1. **Key Aggregation (MuSig2):** Multiple signers with keys $P_1, P_2$ can produce a single 64-byte signature that looks identical on-chain to a single-user signature!
2. **Batch Verification:** A node can verify $N$ Schnorr signatures together significantly faster than one-by-one.
3. **Non-Malleability:** Unlike DER-encoded ECDSA signatures (71–73 bytes), BIP340 Schnorr signatures are fixed at **64 bytes** (`R_x || s`).

---

## Chapter 3: Taproot Key Tweaking (BIP341, Stage 07)

Taproot embeds an optional Merkle tree of scripts (`merkle_root` $m$) directly inside a single 32-byte public key $Q$ without revealing that a script even exists:

1. **Internal Key:** $P = k \cdot G$ (with even $y$).
2. **TapTweak Scalar:** $t = \text{TaggedHash}_{\text{TapTweak}}(P_x \parallel m)$.
3. **Tweaked Output Key (on-chain in `OP_1 <32-byte Q>`):**
   $$Q = P + t \cdot G = (k + t) \cdot G$$
4. **Key-Path Spend:** Sign directly with the tweaked private key $k' = (k + t) \bmod n$!

---

## Chapter 4: Address Formats & Hash Pipelines

| Address Type | Prefix (Mainnet / Regtest) | Script Pattern (`scriptPubKey`) | Encoding & Checksum |
| :--- | :--- | :--- | :--- |
| **Legacy P2PKH** | `1...` / `m` or `n...` | `OP_DUP OP_HASH160 <20B pubkeyHash> OP_EQUALVERIFY OP_CHECKSIG` | Base58Check (`DoubleSHA256` 4-byte checksum) |
| **SegWit v0 P2WPKH** | `bc1q...` / `bcrt1q...` | `OP_0 <20B HASH160(pubkey)>` (`0014...`) | Bech32 (**BIP173** polynomial checksum) |
| **SegWit v0 P2WSH** | `bc1q...` / `bcrt1q...` | `OP_0 <32B SHA256(witnessScript)>` (`0020...`) | Bech32 (**BIP173**) |
| **Taproot v1 P2TR** | `bc1p...` / `bcrt1p...` | `OP_1 <32B Tweaked X-Only Key Q>` (`5120...`) | Bech32m (**BIP350** constant `0x2bc830a3`) |

> **Remember:** `HASH160(x) = RIPEMD160(SHA256(x))` (20 bytes). SegWit v0 P2WSH uses **32-byte `SHA256`** instead of 20-byte `HASH160` to prevent 80-bit birthday-bound multisig collision attacks!

---

## 🧠 Blind Recall Challenges (Close This File & Write From Memory!)

1. **Drill 3.1 (Prime Field & Curve):** Write down the exact prime $p = 2^{256} - 2^{32} - 977$ and curve equation $y^2 \equiv x^3 + 7 \pmod p$ for `secp256k1` from memory.
2. **Drill 3.2 (Schnorr Linearity Proof):** Starting from $s = r + e \cdot k \pmod n$, multiply both sides by $G$ on paper to prove why $s \cdot G = R + e \cdot P$.
3. **Drill 3.3 (Taproot Key-Path Tweak):** Write down the formula for the tweaked private key $k'$ and tweaked public key $Q$ given internal private key $k$ and script tree root $m$.
4. **Drill 3.4 (ScriptPubKey Byte Recognition):** Given raw `scriptPubKey` hex `001489abcdef...` (22 bytes) vs `512089abcdef...` (34 bytes), identify from memory which is P2WPKH (`SegWit v0`) and which is P2TR (`Taproot v1`).
