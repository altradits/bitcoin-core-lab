# Stage 04: The Functional Test Framework — Read It, Then Write Your Own Test

> Source checked: `test/functional/` at `v29.0` (`f490f5562d`) and `master` (`e75b76b12c`).
> The framework APIs used here (`BitcoinTestFramework`, `MiniWallet`, `assert_*`, `self.generate`,
> `sync_mempools`) exist in both.

**No-Shortcuts Rule.** You write the whole test yourself, starting from a skeleton made of TODOs.
The previous finished test is now the spoiler in
[`solutions/kisumu_pos_rbf_test.py`](./solutions/kisumu_pos_rbf_test.py); open it only after
`check_functional_test.sh` passes or after **3 honest attempts**. Journal:
`my-work/04-functional-test-framework/journal.md`.

Almost every Bitcoin Core PR that changes behaviour adds or changes a functional test. Reviewers
run them, read them, and ask for more of them. If you cannot write one, you cannot fully review one.

---

## Objectives

| ID | You can... |
|----|------------|
| C-PY-1 | explain the life of a functional test: `set_test_params` → `setup_chain` → `setup_network` → `run_test` → shutdown and cleanup; where the cached 200-block chain comes from |
| C-PY-2 | use `MiniWallet`, `sync_mempools`/`sync_blocks`, `self.generate`, `assert_equal`, `assert_raises_rpc_error`, `wait_until` correctly |
| C-PY-3 | write a deterministic two-node test, run it alone and through `test_runner.py`, and know how to register it in `BASE_SCRIPTS` |
| C-TEST-3 (intro) | prove a test catches a bug by breaking the behaviour it asserts |

## Prerequisites
Stage 03 (you did the same RBF/CPFP flow by hand). A Bitcoin Core build with
`build/test/config.ini` (Stage 13 teaches the build; your machine already has one at
`~/bitcoin/build`).

Estimated time: 12 hours.

---

## Theory

### 1. Anatomy (`test/functional/test_framework/test_framework.py`)
- `set_test_params()` — **required**. Sets `self.num_nodes`, `self.extra_args`,
  `self.setup_clean_chain`, `self.supports_cli`, …
- `skip_test_if_missing_module()` — e.g. `self.skip_if_no_wallet()`.
- `setup_chain()` — copies a cached regtest datadir with **200 blocks** (so 100 coinbase outputs
  are mature) unless `setup_clean_chain = True`.
- `setup_network()` → `setup_nodes()` + connects node *i* to node *i+1*.
- `run_test()` — **required**. Your assertions.
- `main()` parses options (`--configfile`, `--tmpdir`, `--nocleanup`, `--randomseed`,
  `--tracerpc`, `--pdbonfailure`, `--timeout-factor`) and always shuts nodes down.

Read the file's comments yourself; `test/functional/example_test.py` is the official tour and
`test/functional/README.md` the style guide (naming prefixes `feature_`, `mempool_`, `p2p_`,
`rpc_`, `wallet_`, `mining_`, `interface_`, `tool_`).

### 2. MiniWallet (`test_framework/wallet.py`)
A tiny wallet in Python. It needs no wallet support in `bitcoind`, so tests run on builds made
with `-DENABLE_WALLET=OFF`. Default mode `ADDRESS_OP_TRUE` uses a fixed P2TR (bech32m) address whose
coins are spent through a script path that is just `OP_TRUE`, so no signatures are needed
(`MiniWalletMode`; `RAW_P2PK` exists when a test needs real signatures). Key methods: `get_utxo`, `create_self_transfer`,
`send_self_transfer`, `create_self_transfer_multi`, `send_to`, `rescan_utxos`. Each created tx
dict carries `txid`, `wtxid`, `hex`, `tx` and `new_utxo`.

### 3. Determinism
Tests run in parallel on CI, many times a day. A flaky test wastes reviewers' time and gets
reverted. Rules: always `sync_*` or `wait_until` before asserting across nodes; never `sleep`;
use `self.generate(...)` (it syncs for you; `sync_fun=self.no_op` when you deliberately do not
want sync); use mock time (`setmocktime`) for anything time-dependent; seed randomness from the
framework (`--randomseed`).

### 4. Running
```
build/test/functional/test_runner.py <test.py> [--jobs=N]   # registered tests
python3 <your_test.py> --configfile=build/test/config.ini     # any file
```
On the 8 GB M1 keep `--jobs` at 2–3; every test starts real `bitcoind` processes.

### 5. v29 vs master differences that change test expectations
- `incrementalrelayfee` default: 1 sat/vB (v29) → 0.1 sat/vB (master). A "+50 sat" replacement
  that fails rule 4 on v29 is **accepted** on master.
- `getmempoolentry` gains `chunkweight` / `fees.chunk` on master (cluster mempool).

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1 | [Run and read upstream tests](./exercises/01-run-and-read.md) | `./check_anatomy.sh` |
| 2 | [Write the Kisumu POS test from the skeleton](./exercises/02-write-your-test.md) | `./check_functional_test.sh` |
| 3 | [Prove your test catches a bug (mutation)](./exercises/03-mutation.md) | `./check_functional_test.sh --mutation` |

Copy [`exercises/answers.env.template`](./exercises/answers.env.template) to
`my-work/04-functional-test-framework/answers.env`.

---

## Checkpoint

```bash
./lab.sh check 04
```

Runs: ./check_anatomy.sh, ./check_functional_test.sh, ./check_functional_test.sh --mutation. Each prints PASS/FAIL with a reason, never the answer. Needs a Bitcoin Core build with `build/test/config.ini` (Stage 13). The `--mutation` run must make your test FAIL.
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answers in [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_04=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).
1. Which two methods must every functional test define?
2. Why do most tests start with 200 blocks, and how do you opt out?
3. Why is `self.generate(node, 1)` preferred over `node.generatetoaddress(1, addr)`?
4. What does MiniWallet's default mode use as its output script, and why does that make tests fast?
5. Name three ways a functional test becomes flaky and the fix for each.
6. Where do you register a new test so CI runs it, and what naming prefix would a mempool-policy test use?
7. Your assertion passed on v29 but fails on master: the "+50 sat" replacement is accepted. Why?
8. What does `assert_raises_rpc_error(-26, "msg", fn, arg)` check, and what happens if `fn` succeeds?

---

## Review lens
When a PR adds or changes a functional test:
- Run it alone **and** with `--jobs` in `test_runner.py`; run it several times
  (`for i in $(seq 10); do …; done`) to look for flakiness.
- Read it for: missing syncs, sleeps, hard-coded fees that depend on defaults that may change,
  assertions that would still pass if the feature were removed (mutation thinking).
- Check registration in `test/functional/test_runner.py` and the file name prefix.
- Useful references: `test/functional/README.md`, `test/functional/example_test.py`,
  `test_framework/wallet.py`, `test_framework/p2p.py` (Stage 14).

## Proof-of-work output
Your own passing test file in `my-work/04-functional-test-framework/`. Later (Stage 19) the
same skill produces a real upstream contribution: a test-coverage PR or a test you write while
reviewing someone else's PR.
