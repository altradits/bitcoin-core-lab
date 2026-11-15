# Stage 06 Worksheet 1: Assemble the HTLC script by hand

**Output:** answers in "Worksheet 1". **Checker:** `./check_htlc_script.sh` (offline; it parses your hex).

## Step 1 — your own secret and keys
1. Choose a 32-byte preimage `R` (e.g. the hex of a 32-character phrase of your own).
   → `PREIMAGE_HEX`. Compute `H = SHA256(R)` with `python3 -c 'import hashlib; …'` or `shasum -a 256`
   on the raw bytes (careful: hash the bytes, not the hex text). → `PAYMENT_HASH_HEX`
2. Make two key pairs whose private keys **you** hold (Worksheet 2 signs with them): in Python,
   `from test_framework.key import ECKey`, then `k = ECKey(); k.set(<32 secret bytes>, True)` and
   `k.get_pubkey().get_bytes().hex()`. Use a secret of your own for each (e.g. SHA256 of a phrase).
   → `MERCHANT_PUBKEY`, `SENDER_PUBKEY` (33-byte compressed, starting `02` or `03`).
   Regtest only: never derive real keys from phrases.
3. Choose `CSV_DELAY` between 5 and 20 blocks.

## Step 2 — assemble on paper
Write the script hex **by hand**, one item per line in your journal: opcode byte or push length +
data. Use `src/script/script.h` (the `opcodetype` enum) for opcode values. → `HTLC_SCRIPT_HEX`

<details><summary>Hint 1 (pushes)</summary>

A 32-byte push is the byte `0x20` followed by the data; a 33-byte pubkey push is `0x21` + data.
Small integers 1–16 have their own opcodes (`OP_1`..`OP_16`); see `CScript::EncodeOP_N`.
</details>

## Step 3 — the P2WSH output
Compute `SHA256(script bytes)` and write the scriptPubKey → `P2WSH_SPK_HEX`.
Only **now** confirm with `bitcoin-cli decodescript <your hex>`: does the `segwit` section show
the same scriptPubKey hex? Record its `address` → `P2WSH_ADDRESS`.

## Step 4 — journal
Which item of the claim witness ends up on top of the stack when `OP_IF` runs? Draw the stack
before every opcode for the claim path.
