# Stage 04: Python functional tests

You run two upstream functional tests, then run a custom two node test
that replays Stage 03 over P2P: relay, RBF rejection, cross node
eviction, CPFP package sync, and ordered confirmation.

## Goal

After this stage you can run any upstream functional test and write
your own test with `BitcoinTestFramework` and `MiniWallet`.

## Why it matters

Bitcoin Core reviews require functional tests for behavior changes.
The framework (`test/functional/test_framework/`) spawns real nodes in
temporary datadirs, connects them over P2P, and syncs them
deterministically. `MiniWallet` builds SegWit transactions in pure
Python with no wallet database. Contributing upstream means writing
tests like the one in this stage.

## Prerequisites

* Stage 03 (you know RBF and CPFP by hand; this stage automates them).
* A compiled Bitcoin Core tree with functional tests enabled. The lab
  default path is `~/bitcoin`. See
  BUILDING_BITCOIN_CORE_FROM_SOURCE.md if you have not built yet.
* Python 3.10 or later.

## Setup

Point the lab at your Bitcoin Core checkout and confirm the test
runner exists:

```bash
export BITCOIN_ROOT="$HOME/bitcoin"
ls "$BITCOIN_ROOT/build/test/functional/test_runner.py"
```

Expected output:

```text
/Users/mac/bitcoin/build/test/functional/test_runner.py
```

(Your home path differs.) Every command below needs `BITCOIN_ROOT`
set. Add the export to your shell profile to keep it.

## Steps

### Step 1: Run two upstream tests

```bash
python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" feature_rbf.py mempool_packages.py
```

Expected output:

```text
TEST                | STATUS    | DURATION

feature_rbf.py      | Passed    | 13 s
mempool_packages.py | Passed    | 4 s

ALL                 | Passed    | 17 s (accumulated)
Runtime: 13 s
```

Durations differ on your machine. Both must say Passed. These are the
upstream tests for the behavior you did by hand in Stage 03.

### Step 2: Run the custom two node test

```bash
python3 ./04-functional-test-framework/kisumu_pos_rbf_test.py --configfile="$BITCOIN_ROOT/build/test/config.ini"
```

Expected output (seed and directory differ):

```text
TestFramework (INFO): PRNG seed is: 4405568864662296658
TestFramework (INFO): Initializing test directory /var/folders/8k/.../T/bitcoin_func_test_so1_bc6a
TestFramework (INFO): 1. Broadcasting initial low-fee RBF transaction (200 sats) on Node 0...
TestFramework (INFO): 2. Verifying PaysForRBF Rule #4 rejection (+50 sats < incremental relay fee)...
TestFramework (INFO): 3. Broadcasting valid BIP125 replacement (5,000 sats) and verifying P2P eviction...
TestFramework (INFO): 4. Broadcasting high-fee CPFP child (20,000 sats) from Merchant Node 1...
TestFramework (INFO): 5. Mining confirmation block and verifying topological ordering...
TestFramework (INFO): Stopping nodes
TestFramework (INFO): Cleaning up /var/folders/8k/.../T/bitcoin_func_test_so1_bc6a on exit
TestFramework (INFO): Tests successful
```

The test asserts five things across Node 0 (customer) and Node 1
(merchant):

1. `tx_v1` relays to Node 1 with `bip125-replaceable: True`.
2. `tx_v2_bad` (+50 sats) is rejected with `not enough additional
   fees to relay`.
3. `tx_v2_good` (5,000 sats) evicts `tx_v1` from both nodes.
4. The child from Node 1 syncs back with `ancestorcount == 2` and
   ancestor fees of 0.00025000 BTC.
5. One mined block holds parent at index 1 and child at index 2.

### Step 3: Read the test code

Open [kisumu_pos_rbf_test.py](./kisumu_pos_rbf_test.py). It is 93
lines. Notice the three framework pieces:

* `set_test_params` declares two nodes.
* `MiniWallet(customer_node)` funds transactions without a wallet
  database. `create_self_transfer` builds and signs in Python.
* `self.sync_mempools()` blocks until both nodes hold the same
  mempool, which makes P2P assertions deterministic.

## Checkpoint

```bash
./lab.sh check 04
```

Expected output:

```text
PASS: stage 04. custom two node test passed; upstream rbf and package tests passed.
```

The check runs Step 1 and Step 2 and requires all three files to pass.
You can also rerun the Step 2 command by hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `No such file or directory: .../test_runner.py` | Core was not built, or `BITCOIN_ROOT` is wrong | Build first (see the build manual); `echo $BITCOIN_ROOT` to check |
| `Config file not found` | Wrong `--configfile` path | Use `$BITCOIN_ROOT/build/test/config.ini` exactly |
| `Address already in use` | A previous test run left nodes behind | Wait 30 seconds and retry; the framework cleans up on exit |
| `AssertionError` mid test | Usually a stale datadir or a code edit | Rerun; if it repeats, open a lab bug issue with the output |

## Going further

1. Break the test on purpose. Change the assertion on
   `ancestorcount` from 2 to 3, rerun, and read the failure. Then
   revert. Done when you can explain what the failure line means.
2. Add a sixth assertion. After step 5, assert the merchant node
   balance of the child output with `gettxout`. Done when the test
   passes with your new line.
3. Read an upstream test. Open
   `test/functional/feature_rbf.py` in your checkout and find where it
   tests Rule 4. Done when you can name the function.

## Contribution task

Review open upstream test issues for one that reproduces on your
machine. Run it, and if it fails, report the exact failure with your
OS and commit hash on the issue. A concrete starting point: run
`mempool_truc.py` (used in Stage 05) and confirm it passes:

```bash
python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" mempool_truc.py
```

Expected: `mempool_truc.py | Passed`. If it fails, open a lab bug
issue first.

## Sources

* `test/functional/README.md` in bitcoin/bitcoin: how to run the
  suite.
* `test/functional/test_framework/test_framework.py`
  (`BitcoinTestFramework`): node setup and sync helpers.
* `test/functional/test_framework/wallet.py` (`MiniWallet`):
  framework wallet.
* `test/functional/feature_rbf.py` and
  `test/functional/mempool_packages.py`: the upstream tests from
  Step 1.
