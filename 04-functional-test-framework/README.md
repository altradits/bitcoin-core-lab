# Hour 04: Bitcoin Core Functional Test Framework (`BitcoinTestFramework` & `MiniWallet`)

## Objective
Run upstream Bitcoin Core Python functional tests (`feature_rbf.py`, `mempool_packages.py`) via `build/test/functional/test_runner.py` and author a custom two-node P2P functional test (`kisumu_pos_rbf_test.py`) using `BitcoinTestFramework` and descriptor-less `MiniWallet` (`test/functional/test_framework/wallet.py`) to programmatically verify multi-node mempool synchronization, `PaysForRBF` Rule #4 rejection, P2P conflict eviction, and CPFP topological block assembly.

---

## 1. Upstream Test Framework Architecture

- **`BitcoinTestFramework` (`test/functional/test_framework/test_framework.py`):**
  Spawns isolated `bitcoind -regtest` instances in temporary datadirs, pre-mines a deterministic 200-block chain (providing 100 mature coinbase outputs), connects nodes over P2P, and provides deterministic synchronization helpers (`self.sync_mempools()`, `self.sync_blocks()`, `self.generate()`).
- **`MiniWallet` (`test/functional/test_framework/wallet.py`):**
  A lightweight, zero-dependency Python wallet used in modern Bitcoin Core tests that constructs and signs SegWit v0 (`P2WPKH`) and Taproot (`P2TR`) transactions directly in Python without requiring `bitcoind` to compile with BerkeleyDB or SQLite wallet support.

---

## 2. Running Upstream Consensus & Mempool Tests

```bash
python3 build/test/functional/test_runner.py feature_rbf.py mempool_packages.py
```

```text
TEST                | STATUS    | DURATION

feature_rbf.py      | ✓ Passed  | 6 s
mempool_packages.py | ✓ Passed  | 2 s

ALL                 | ✓ Passed  | 8 s (accumulated) 
Runtime: 6 s
```

---

## 3. Custom Two-Node Functional Test (`kisumu_pos_rbf_test.py`)

`kisumu_pos_rbf_test.py` provisions two connected `bitcoind` regtest nodes (`Node 0: Customer/Miner` and `Node 1: Kisumu POS Merchant`) and asserts five protocol invariants end-to-end:

1. **P2P Relay & BIP125 Opt-In:** Node 0 broadcasts `tx_v1` (`200 sats` fee, `nSequence = MAX_BIP125_RBF_SEQUENCE = 0xfffffffd`), calls `self.sync_mempools()`, and asserts `tx_v1` arrives in Node 1's mempool with `bip125-replaceable: True`.
2. **DoS Rule #4 (`PaysForRBF`) Assertion:** Node 0 attempts to broadcast `tx_v2_bad` (`250 sats` fee, `+50 sats < incrementalrelayfee`) and verifies rejection via:
   ```python
   assert_raises_rpc_error(
       -26,
       "not enough additional fees to relay",
       customer_node.sendrawtransaction,
       tx_v2_bad["hex"],
   )
   ```
3. **Cross-Node P2P Eviction:** Node 0 broadcasts `tx_v2_good` (`5,000 sats` fee), syncs mempools over P2P, and verifies `tx_v1` is evicted from both `Node 0` and `Node 1`.
4. **CPFP Package Propagation:** Node 1 broadcasts `tx_child` (`20,000 sats` fee) spending `tx_v2_good["new_utxo"]`, syncs mempools back to Node 0, and asserts `ancestorcount == 2` and `fees.ancestor == 0.00025000 BTC`.
5. **Topological Block Inclusion:** Node 0 mines 1 block (`self.generate(customer_node, 1)`), syncs blocks to Node 1, and asserts `block["tx"][1] == tx_v2_good["txid"]` and `block["tx"][2] == tx_child["txid"]`.

### Execution Output
```bash
python3 04-functional-test-framework/kisumu_pos_rbf_test.py --configfile=/Users/mac/bitcoin/build/test/config.ini
```
```text
2026-10-17T17:55:52.825000Z TestFramework (INFO): PRNG seed is: 376104147453436943
2026-10-17T17:55:52.825000Z TestFramework (INFO): Initializing test directory /var/folders/8k/m9c3l5b911zgz_frwt6skg280000gn/T/bitcoin_func_test_gs3wiotm
2026-10-17T17:55:53.819000Z TestFramework (INFO): 1. Broadcasting initial low-fee RBF transaction (200 sats) on Node 0...
2026-10-17T17:56:10.980000Z TestFramework (INFO): 2. Verifying PaysForRBF Rule #4 rejection (+50 sats < incremental relay fee)...
2026-10-17T17:56:10.983000Z TestFramework (INFO): 3. Broadcasting valid BIP125 replacement (5,000 sats) and verifying P2P eviction...
2026-10-17T17:56:27.135000Z TestFramework (INFO): 4. Broadcasting high-fee CPFP child (20,000 sats) from Merchant Node 1...
2026-10-17T17:56:31.174000Z TestFramework (INFO): 5. Mining confirmation block and verifying topological ordering...
2026-10-17T17:56:31.240000Z TestFramework (INFO): Stopping nodes
2026-10-17T17:56:31.399000Z TestFramework (INFO): Cleaning up /var/folders/8k/m9c3l5b911zgz_frwt6skg280000gn/T/bitcoin_func_test_gs3wiotm on exit
2026-10-17T17:56:31.399000Z TestFramework (INFO): Tests successful
```
