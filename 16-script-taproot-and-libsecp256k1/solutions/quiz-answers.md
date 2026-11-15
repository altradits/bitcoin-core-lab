# Stage 16 — Self-check quiz answers (SPOILERS)

Answer from memory first. Checked against `/Users/mac/bitcoin` 29.x (`f490f5562d`) and `master` (`e75b76b12c`).

1. `GetBlockScriptFlags` in `src/validation.cpp`. `SCRIPT_VERIFY_P2SH | SCRIPT_VERIFY_WITNESS | SCRIPT_VERIFY_TAPROOT`
   are on for every block except the entries in `consensus.script_flag_exceptions` (one BIP16 block and
   one Taproot block on mainnet, set in `src/kernel/chainparams.cpp`). DERSIG, CLTV, CSV and NULLDUMMY
   are added by `DeploymentActiveAt(...)`.

2. `MANDATORY_SCRIPT_VERIFY_FLAGS` are consensus rules (P2SH, DERSIG, NULLDUMMY, CLTV, CSV, WITNESS,
   TAPROOT). `STANDARD_SCRIPT_VERIFY_FLAGS` adds policy-only rules. The comment in `policy.h` says Core
   does **not** ban or disconnect peers that relay txs breaking only the non-mandatory rules — it just
   does not accept/relay the tx. That keeps old and new nodes able to talk during upgrades.

3. BIP143 commits to the **amount** of the input being signed (and caches hashPrevouts/hashSequence/
   hashOutputs, removing quadratic hashing). Without the amount, a hardware wallet signing an input
   could be lied to about its value and tricked into paying a huge fee. (BIP341 goes further: all
   amounts and all spent scriptPubKeys.)

4. `[stack inputs..., script, control block, (annex)]`. The annex is recognised when there are at least
   two witness elements and the last one starts with `0x50` (`ANNEX_TAG`). It is popped before
   anything else in the v1 branch of `VerifyWitnessProgram`.

5. So that the control block does not need to say whether each node is a left or right child.
   Sorting makes a branch hash a function of the *set* of its two children, which saves a bit per
   level and makes the commitment unambiguous.

6. Consensus: `ExecuteWitnessScript` scans the tapscript for any `OP_SUCCESSx` (`IsOpSuccess`) before
   execution; if found, the script succeeds immediately (unparseable scripts after it don't matter).
   Policy: `SCRIPT_VERIFY_DISCOURAGE_OP_SUCCESS` is in the standard flags, so the tx is rejected from
   the mempool (`SCRIPT_ERR_DISCOURAGE_OP_SUCCESS`). Valid in blocks, not relayed — reserved for future soft forks.

7. (97 − 33) / 32 = 2 → the leaf is at depth 2. Byte 0 = `leaf_version | parity` where leaf version
   is `0xc0` for tapscript (masked with `TAPROOT_LEAF_MASK = 0xfe`) and the low bit is the parity of
   the output key Q's y coordinate.

8. No meaning has been defined for it yet. If people used it now, a future soft fork that gives it
   meaning could break their transactions (or they could use it as cheap data). Keeping it
   non-standard keeps the upgrade path clean. It is signed over (annex hash in the sighash) so it
   cannot be malleated by third parties.

9. Upstream to `bitcoin-core/secp256k1`. `src/secp256k1` is a git subtree; Core only pulls squashed
   updates. Direct edits would be rejected (and `test/lint/git-subtree-check.sh` detects them).
   Crypto review (constant time, math, vectors) happens in the library repo.

10. `VALIDATION_WEIGHT_PER_SIGOP_PASSED` (50) for each signature check with a non-empty signature.
    The budget starts at witness size + `VALIDATION_WEIGHT_OFFSET` (50). This ties the cost of
    signature checks to how many bytes the spender paid for, so sigops no longer need a global
    per-block count for tapscript and batch-validation-friendly limits stay local to each input.
