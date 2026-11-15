# Stage 10 quiz answers (spoilers)

1. Reversed: the raw (internal) bytes start `6f e2 8c 0a b6 f1 b3 72 …` and end with the zero bytes `… 19 d6 68 00 00 00 00 00`. The leading zeros of the display hex are the *last* raw bytes (the most significant bytes of the little-endian number).
2. 252 → `fc`; 253 → `fd fd 00`; 65535 → `fd ff ff`; 65536 → `fe 00 00 01 00`.
3. A legacy parser reads the byte after the version as the input count; 0 inputs would be invalid anyway (`bad-txns-vin-empty`), so `00 01` is unambiguous: marker 0x00 then flag 0x01 (BIP144). Core's `UnserializeTransaction` handles this explicitly, which is why a genuinely empty-input tx needs care in tests.
4. Exponent 0x1d = 29, mantissa 0x00ffff → target = 0xffff × 256^(29−3) = 0x00000000ffff0000…0000 (the mainnet `powLimit`, difficulty 1).
5. Actual timespan is clamped to [nPowTargetTimespan/4, nPowTargetTimespan×4] (3.5 days to 8 weeks): difficulty changes by at most 4× per 2016 blocks, which limits the damage of timestamp manipulation and sudden hashrate swings. The new target is also capped at `powLimit`.
6. Duplicating the last hash on odd levels means a block's tx list can be altered (duplicate the last tx(s)) without changing the Merkle root, so a node that cached "this header is invalid" after seeing the mutated (invalid) version would reject the real block. Core detects equal adjacent pairs (`mutated`) and rejects such a block as `bad-txns-duplicate` without permanently marking the block hash invalid.
7. Domain separation: a hash computed for one purpose (challenge, nonce, tapleaf…) can never be valid in another context. Prefixing SHA256(tag)‖SHA256(tag) is also cheap because the first 64 bytes can be precomputed.
8. Bech32's checksum does not catch inserting or deleting `q` characters just before a final `p`. For v0 the fixed program lengths make this harmless; for v1+ with variable lengths it is not, so BIP350 changed the constant.
9. −1 → `81`; 128 → `80 00` (the high bit of `80` would be the sign bit, so a `00` byte is added).
