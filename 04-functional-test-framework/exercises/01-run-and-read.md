# Stage 04 Worksheet 1: Run and read upstream tests

**Output:** answers in "Worksheet 1". **Checker:** `./04-functional-test-framework/check_anatomy.sh` (offline).

Work in `~/bitcoin`. Keep `--jobs` ≤ 3 on the 8 GB M1.

## Step 1 — run
1. Run `example_test.py` and `feature_rbf.py` through the test runner. Record the runtime of each
   in your journal.
2. Run `example_test.py` **directly** with `--nocleanup` and find its temporary directory in the
   log. Look inside: which node directories exist? Open one `debug.log`. → `EXAMPLE_NUM_NODES`
3. Run `feature_rbf.py --tracerpc` and find the first `sendrawtransaction` call in the output.

<details><summary>Hint 1</summary>

The runner lives in the build directory: `build/test/functional/test_runner.py`. A test run
directly needs `--configfile` pointing at `build/test/config.ini`.
</details>

## Step 2 — read the framework (answer from the source, not memory)
In `test/functional/test_framework/`:
1. How many blocks does the cached chain contain? (Search `test_framework.py` and `util.py` for
   the cache.) → `CACHE_BLOCKS`
2. Name of the method in `BitcoinTestFramework` that waits until every node has the same mempool
   → `MEMPOOL_SYNC_METHOD`
3. Name of the `MiniWallet` method that creates (but does not send) a 1-in-1-out tx →
   `CREATE_ONE_METHOD`
4. Default `MiniWalletMode` name → `MINIWALLET_DEFAULT_MODE`
5. The list in `test_runner.py` where a normal new test is registered → `REGISTER_LIST`
6. The command-line option that keeps the temp directory after the run → `KEEP_TMP_OPTION`
   (including the leading dashes).

## Step 3 — read one real test
Open `test/functional/mempool_accept.py`. In your journal list five reject reasons it asserts and,
for each, whether it is consensus or policy (Stage 02 skill).
