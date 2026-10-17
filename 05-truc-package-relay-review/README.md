# Hour 05: Upstream PR Review — BIP431 TRUC (`v3`) Policy & 1P1C Zero-Fee Parent Package Relay

## Objective
Review and empirically verify Bitcoin Core's **BIP431 Topologically Restricted Until Confirmation (TRUC / `version=3`)** policy (`src/policy/truc_policy.cpp`) and **1-Parent-1-Child (`1P1C`) Package Mempool Acceptance** (`submitpackage` in `src/validation.cpp`), which solve fee-guessing and pinning attacks for Lightning Network commitment transactions.

---

## 1. Upstream Code Review (`src/policy/truc_policy.cpp`)

### Problem Statement: Why Lightning Needed TRUC (`v3`) + `1P1C`
When two Lightning peers sign a commitment transaction today, the commitment transaction might not be broadcast for months. Pre-selecting a valid on-chain feerate at signing time is impossible:
- If the pre-signed feerate is **too low** (`0 sat/vB`, below node `minrelaytxfee`), individual `sendrawtransaction` calls fail with `min relay fee not met`, preventing a CPFP child from ever being attached.
- If the commitment transaction uses legacy `v2` CPFP, a counterparty can attach a large, low-feerate child to **pin** the commitment transaction up to the `101 kvB` descendant limit (`DEFAULT_DESCENDANT_SIZE_LIMIT_KVB`).

### BIP431 Topological Bounds (`src/policy/truc_policy.h` & `src/policy/truc_policy.cpp`)
```cpp
static constexpr decltype(CTransaction::version) TRUC_VERSION{3};
static constexpr int64_t TRUC_ANCESTOR_LIMIT{2};
static constexpr int64_t TRUC_DESCENDANT_LIMIT{2};
static constexpr int64_t TRUC_MAX_VSIZE{10000};
static constexpr int64_t TRUC_CHILD_MAX_VSIZE{1000};
```
In `PackageTRUCChecks` (`src/policy/truc_policy.cpp`):
1. **Strict 1-Parent-1-Child Topology (`TRUC_ANCESTOR_LIMIT == 2`, `TRUC_DESCENDANT_LIMIT == 2`):** A `version=3` transaction can have at most 1 unconfirmed ancestor or 1 unconfirmed descendant.
2. **Bounded Child Size (`TRUC_CHILD_MAX_VSIZE = 1000 vB`):** Prevents descendant size pinning so any sibling eviction costs at most `1,000 vB` of fee-bump bandwidth.
3. **Version Inheritance:** A `version=3` parent can **only** be spent by a `version=3` child while unconfirmed (`non-version=3 tx ... cannot spend from version=3 tx`).

---

## 2. Empirical Reproduction & Boundary Tests on Regtest

### Test 1: Upstream Functional Suite (`mempool_truc.py`)
```bash
python3 build/test/functional/test_runner.py mempool_truc.py
```
```text
TEST            | STATUS    | DURATION
mempool_truc.py | ✓ Passed  | 6 s
```

### Test 2: Standalone Zero-Fee `version=3` Parent (`sendrawtransaction`)
Constructed a `0-fee` `version=3` transaction (`c49c7ca3120c45298104dd8b666a60c6224bb2aa3d7b53bbeda6294c266cc38a`, `110 vB`, input `= 21.99985000 BTC`, output `= 21.99985000 BTC`) and attempted standalone broadcast:
```text
error code: -26
error message:
min relay fee not met, 0 < 110
```

### Test 3: `submitpackage` Version Inheritance Violation (`v3` Parent + `v2` Child)
Submitting the `0-fee` `version=3` parent alongside a `version=2` child (`23879355...`) via `submitpackage`:
```json
{
  "package_msg": "TRUC-violation, non-version=3 tx 23879355a8a97ef66a5d0e6061644653c567cb57afaee017da6fc950342b3a8d (wtxid=5506907fb5bda62b30789ef86654f233a61e581d1cb72b63ac5952881d10c396) cannot spend from version=3 tx c49c7ca3120c45298104dd8b666a60c6224bb2aa3d7b53bbeda6294c266cc38a (wtxid=15dcc51f32da6025e23af6524f8508f963190a7c2f26f557bf5a2e428eaf360b)"
}
```

### Test 4: Valid 1P1C Atomic Package Acceptance (`0-fee v3 Parent` + `10,000 sat v3 Child`)
Patching the child transaction to `version=3` (`6452fff7e1e66f86928129867d78dc134bf41560e2cd0137e0fa2f6b723117b8`, paying `0.00010000 BTC` / `10,000 sats`) and submitting both via `submitpackage`:
```json
{
  "package_msg": "success",
  "tx-results": {
    "15dcc51f32da6025e23af6524f8508f963190a7c2f26f557bf5a2e428eaf360b": {
      "txid": "c49c7ca3120c45298104dd8b666a60c6224bb2aa3d7b53bbeda6294c266cc38a",
      "vsize": 110,
      "fees": {
        "base": 0.00000000,
        "effective-feerate": 0.00045454,
        "effective-includes": [
          "15dcc51f32da6025e23af6524f8508f963190a7c2f26f557bf5a2e428eaf360b",
          "ea34b16c4013605a0163e9cd6350741ed0daf3e19f36bf3d916163447c16bf37"
        ]
      }
    },
    "ea34b16c4013605a0163e9cd6350741ed0daf3e19f36bf3d916163447c16bf37": {
      "txid": "6452fff7e1e66f86928129867d78dc134bf41560e2cd0137e0fa2f6b723117b8",
      "vsize": 110,
      "fees": {
        "base": 0.00010000,
        "effective-feerate": 0.00045454,
        "effective-includes": [
          "15dcc51f32da6025e23af6524f8508f963190a7c2f26f557bf5a2e428eaf360b",
          "ea34b16c4013605a0163e9cd6350741ed0daf3e19f36bf3d916163447c16bf37"
        ]
      }
    }
  }
}
```
Notice how `MemPoolAccept::AcceptPackage` evaluates both `wtxid`s as a single `220 vB` chunk with `"effective-feerate": 0.00045454 BTC/kvB` (`45.45 sat/vB`), allowing the **`0.00000000` base-fee parent** to enter the mempool atomically alongside its child.
