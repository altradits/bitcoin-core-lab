# Stage 16 — Worksheet notes (SPOILERS)

Open only after your own answers are written. These are *notes*, not full answers: you still need
your own explanation in your own words.

## 16.1
- Part A: `ExecuteWitnessScript`, `VerifyWitnessProgram`, `EvalChecksigTapscript` are `static`
  (file-local) → only reachable through `VerifyScript`/`EvalScript`, so tests and fuzzers exercise them
  through the public entry points. Block validation wraps `VerifyScript` in `CScriptCheck`
  (`src/validation.h`) whose `operator()` is run by the check queue workers.
- Part B: P2WPKH → `VerifyScript` → `EvalScript(scriptSig)` (empty) → `EvalScript(scriptPubKey)` leaves
  `[0, <20 bytes>]`... → `IsWitnessProgram` → `VerifyWitnessProgram(witversion 0, 20-byte program)` →
  requires exactly 2 witness items → builds `OP_DUP OP_HASH160 <program> OP_EQUALVERIFY OP_CHECKSIG` →
  `ExecuteWitnessScript(..., SigVersion::WITNESS_V0, ...)`.
- Part C: order of checks: TAPROOT flag → stack non-empty (`WITNESS_PROGRAM_WITNESS_EMPTY`) → annex pop
  → key path or script path → control size (`TAPROOT_WRONG_CONTROL_SIZE`) → leaf hash →
  `VerifyTaprootCommitment` (`WITNESS_PROGRAM_MISMATCH`) → leaf version 0xc0 → validation weight =
  serialized witness size + 50 → `ExecuteWitnessScript` (OP_SUCCESSx scan first, stack item limits)
  → unknown leaf version: success, or `DISCOURAGE_UPGRADABLE_TAPROOT_VERSION` under standard flags.
- Part D: bits 0..20 at 29.x; on master the same names are `enum class script_verify_flag_name`
  members wrapped in `script_verify_flags` (PR #32998).

## 16.2
- Legacy `SIGHASH_SINGLE` with `nIn >= txTo.vout.size()` returns `uint256::ONE`: a signature over "1"
  is valid for *any* transaction with that shape → anyone can reuse it to spend that coin.
- Suite name for 16.2 Part C: `sighash_tests` (`BOOST_FIXTURE_TEST_SUITE(sighash_tests, SigHashTest)`).

## 16.3
- Key-path witness: one 64-byte signature (65 if a non-default sighash type was used).
- Script-path witness for `pk(B)`: `[sig_B (64), <32-byte B> OP_CHECKSIG (34 bytes), control block (33)]`.
- Single-leaf tree: merkle root = leaf hash; control block = 33 bytes (depth 0).
- The key path is smaller (no script, no control block) → cheaper, and indistinguishable from a
  single-key spend. Put the common case in the key path.
- The stretch annex attempt fails policy with `bad-witness-nonstandard` (from `IsWitnessStandard`).

## 16.4
- See `solutions/tagged_hash.py`. Trap: the `sigMsg` field in `bip341_wallet_vectors.json` already
  starts with the 0x00 epoch byte.

## 16.5
- Flag names are parsed by `mapFlagNames` in `src/test/transaction_tests.cpp`; an unknown name fails
  the test (`BOOST_ERROR` "Bad test: unknown verification flag ...").
- Single case: `test_bitcoin --run_test=script_tests/script_json_test`.
- `feature_taproot.py --dumptests` writes cases to `$TEST_DUMP_DIR`; they feed the
  `script_assets_test` unit test (via `script_assets_test.json`) and the fuzz minimizer.

## 16.6
- Toy curve: nonce reuse recovery: k = (z1 − z2)/(s1 − s2), then d = (s1·k − z1)/r (mod n).
- `secp256k1_context_static` for verification (no secret data), `secp256k1_context_sign` for signing.
- MuSig2 key-aggregation coefficients defeat the rogue-key attack (a participant choosing
  P_evil = P_target − P_honest).
