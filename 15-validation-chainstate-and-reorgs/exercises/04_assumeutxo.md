# Stage 15 Exercise 4: AssumeUTXO — read and run

**Output:** journal answers.

1. Read `doc/design/assumeutxo.md` (master). In your words: what is trusted, what is verified
   later, and what happens on mismatch?
2. Find `m_assumeutxo_data` for regtest in `src/kernel/chainparams.cpp`. Why must the snapshot
   hash be **hard-coded in the source** rather than accepted from the user?
3. Run `feature_assumeutxo.py` with `--nocleanup`. While reading its code, list every RPC it calls
   (`dumptxoutset`, `loadtxoutset`, `getchainstates`, …) and what it asserts after each.
4. Find where the background chainstate's final hash is compared with the snapshot
   (search `MaybeValidateSnapshot`/`ValidatedSnapshotCleanup` or similar on master; names have
   changed across versions — record what you find on 29.x and on master).
5. Which wallet limitation applies while the background chainstate is still syncing? (Search
   the doc and `wallet_assumeutxo.py`.)
