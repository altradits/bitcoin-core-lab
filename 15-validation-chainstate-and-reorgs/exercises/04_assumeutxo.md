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

## Checkable facts

After you have answered the questions above in your journal, put these short answers in
`my-work/15-validation-chainstate-and-reorgs/answers.env` (one `KEY=value` per line) and run
`python3 tools/check_facts.py 15-validation-chainstate-and-reorgs 15.4` from the lab root (or `./lab.sh check 15`).
Answers are for master `e75b76b12c` and 29.x `f490f5562d`. The checker says which ones are wrong, never the right value.
Your explanations (the "why" questions) are not machine-checked: compare them with `solutions/` afterwards.

| Key | Question |
|---|---|
| `F15_DUMP_RPC` | q3: the RPC that writes a UTXO snapshot |
| `F15_LOAD_RPC` | q3: the RPC that loads one |
| `F15_STATES_RPC` | q3: the RPC that lists the chainstates |
| `F15_VALIDATE_FN_29` | q4: the `ChainstateManager` method on 29.x that compares the background hash with the snapshot |
| `F15_VALIDATE_FN_MASTER` | q4: its name on master |
