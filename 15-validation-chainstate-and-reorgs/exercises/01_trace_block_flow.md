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
