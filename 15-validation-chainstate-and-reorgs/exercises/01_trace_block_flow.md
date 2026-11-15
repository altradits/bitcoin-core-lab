# Stage 15 Exercise 1: Trace a block through the code

**Output:** journal answers. Compare with [`../solutions/trace_answers.md`](../solutions/trace_answers.md) only afterwards.

Work in `src/validation.cpp` (master: `git show master:src/validation.cpp | less`, or a master worktree).

1. Starting at `ChainstateManager::ProcessNewBlock`, list every function called until the block is
   stored, in order. Which of them take `cs_main`?
2. In `CheckBlock`, list the checks in order and give each reject reason string (`bad-txnmrklroot`, …).
   Why is the Merkle-root check first?
3. In `ContextualCheckBlockHeader`, which check uses `GetNextWorkRequired`, and which uses
   median-time-past? What is the "time-too-new" bound?
4. In `ContextualCheckBlock`, find BIP34 (height in coinbase) and the witness commitment check.
   Which flags/deployments enable them?
5. In `ConnectBlock`, find: the BIP30 check (duplicate txids), the sigop limit, the call that checks
   inputs and amounts, where scripts are checked (and how they are parallelised: `CCheckQueue`),
   and the subsidy check (`bad-cb-amount`).
6. In `ActivateBestChainStep`, how far does it disconnect and how many blocks does it connect per
   call? Why does `ActivateBestChain` release `cs_main` between steps?
7. Follow a disconnected tx: from `DisconnectTip` to `MaybeUpdateMempoolForReorg`. What filter does
   `removeForReorg` apply?
8. Use `lldb` (Stage 17) or `-debug=validation` logging on regtest to see one block go through
   `UpdateTip`. Paste the log lines and annotate them.

## Checkable facts

After you have answered the questions above in your journal, put these short answers in
`my-work/15-validation-chainstate-and-reorgs/answers.env` (one `KEY=value` per line) and run
`python3 tools/check_facts.py 15-validation-chainstate-and-reorgs 15.1` from the lab root (or `./lab.sh check 15`).
Answers are for master `e75b76b12c`. The checker says which ones are wrong, never the right value.
Your explanations (the "why" questions) are not machine-checked: compare them with `solutions/` afterwards.

| Key | Question |
|---|---|
| `F15_MERKLE_REJECT` | q2: the reject reason for a wrong Merkle root |
| `F15_FUTURE_REJECT` | q3: the reject reason for a block too far in the future |
| `F15_MAX_FUTURE_SECONDS` | q3: that bound in seconds |
| `F15_BIP30_REJECT` | q5: the reject reason for the BIP30 duplicate-txid check |
| `F15_SUBSIDY_REJECT` | q5: the reject reason when the coinbase pays too much |
| `F15_SCRIPT_QUEUE` | q5: the class template that runs script checks in parallel |
| `F15_REORG_MEMPOOL_FN` | q7: the mempool method called with the reorg filter |
