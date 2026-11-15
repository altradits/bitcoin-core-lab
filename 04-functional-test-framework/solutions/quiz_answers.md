# Stage 04 quiz answers (spoilers)

1. `set_test_params` and `run_test`.
2. The framework copies a cached chain of 200 blocks so 100 coinbase outputs are already mature (coinbase maturity is 100). Set `self.setup_clean_chain = True` to start from genesis.
3. `self.generate` calls the RPC and then syncs all nodes (`sync_all`) unless you pass `sync_fun`. That removes a whole class of races. It also lets the framework track which node generated what.
4. `ADDRESS_OP_TRUE`: a fixed P2TR address whose script path is `OP_TRUE`. Anyone can spend it and no signing is needed, so tx creation is fast and needs no wallet build.
5. (a) Asserting on another node before relay finished → `sync_mempools`/`sync_blocks`/`wait_until`. (b) `sleep()` timing assumptions → `wait_until` with a predicate. (c) Wall-clock time or randomness → `setmocktime` and the framework seed (`--randomseed`). Also: port collisions when run outside the runner, hard-coded fees that depend on defaults.
6. `BASE_SCRIPTS` (or `EXTENDED_SCRIPTS` for long tests) in `test/functional/test_runner.py`. Prefix `mempool_`.
7. Master's default incremental relay feerate is 0.1 sat/vB (PR #33106), so rule 4 needs only ~ceil(0.1 × vsize) extra sats; +50 is enough.
8. That calling `fn(arg)` raises a `JSONRPCException` whose code is -26 and whose message contains "msg". If `fn` succeeds, it raises `AssertionError("No exception raised")`, so the test fails.
