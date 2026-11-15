# Stage 05: TRUC version 3 and package relay

You verify how a zero fee parent can enter the mempool together with
its fee paying child in one atomic package, and why the child must
also be version 3.

## Goal

After this stage you can submit a 1 parent 1 child package with
`submitpackage`, read its effective feerate, and explain the TRUC
topology rules.

## Why it matters

Lightning commitment transactions are signed long before they are
broadcast, so nobody can pick the right fee at signing time. BIP431
defines version 3 (TRUC) transactions with tight topology limits: at
most one unconfirmed parent and one unconfirmed child. That bound makes
package RBF safe, so a pre signed zero fee commitment can be fee bumped
at broadcast time with a child. This replaces the old anchor pattern
that attackers could pin with huge low fee children.

## Prerequisites

* Stage 02 (raw transactions; this stage hand builds versions).
* One coin of at least 5 BTC in `kisumu_miner`.
* `BITCOIN_ROOT` set to your Bitcoin Core checkout (for Step 1).

## Setup

```bash
bitcoin-cli -regtest -rpcwallet="kisumu_miner" getbalance
```

Expected output (any value above 5 works):

```text
50.00000000
```

If the balance is too low, run `./lab.sh step 1` to mine more blocks.

## Steps

### Step 1: Run the upstream TRUC test

```bash
python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" mempool_truc.py
```

Expected output (duration differs):

```text
mempool_truc.py | Passed | 8 s
```

This is the upstream suite for the policy you are about to exercise
by hand.

### Step 2: Read the TRUC limits

Open `src/policy/truc_policy.h` in your checkout:

```cpp
static constexpr decltype(CTransaction::version) TRUC_VERSION{3};
static constexpr unsigned int TRUC_DESCENDANT_LIMIT{2};
static constexpr unsigned int TRUC_ANCESTOR_LIMIT{2};
static constexpr int64_t TRUC_MAX_VSIZE{10000};
static constexpr int64_t TRUC_CHILD_MAX_VSIZE{1000};
```

A version 3 transaction counts itself plus at most one unconfirmed
parent (ancestor limit 2) and one unconfirmed child (descendant limit
2). The child that spends it while unconfirmed must itself be version
3, and may not exceed 1000 vB. These bounds cap how much fee bump
bandwidth an attacker can force on you.

### Step 3: Watch a zero fee parent fail alone

Build a zero fee version 3 parent and try to broadcast it by itself.
(The script flips the version bytes from `02000000` to `03000000`
after `createrawtransaction`, because the RPC has no version flag.)

```bash
UTXO=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" listunspent | python3 -c "import sys,json; u=[x for x in json.load(sys.stdin) if x['amount']>=5.0][0]; print(u['txid'], u['vout'], u['amount'])")
read TXID VOUT AMT <<< "$UTXO"
A1=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" getnewaddress)
RAW=$(bitcoin-cli -regtest createrawtransaction "[{\"txid\":\"$TXID\",\"vout\":$VOUT}]" "[{\"$A1\":$AMT}]" 0 true)
SIGNED=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" signrawtransactionwithwallet "03000000${RAW:8}" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
bitcoin-cli -regtest sendrawtransaction "$SIGNED"
```

Expected output (a 110 vB parent):

```text
error code: -26
error message:
min relay fee not met, 0 < 110
```

Zero fee pays nothing, so single transaction relay rejects it. The
fee has to come from the package, which is what Step 5 shows.

### Step 4: Watch a version 2 child fail the package

A version 3 parent may only be spent by a version 3 child while
unconfirmed. Submit the parent from Step 3 with a version 2 child:

```bash
A2=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" getnewaddress)
PTXID=$(bitcoin-cli -regtest decoderawtransaction "$SIGNED" | python3 -c "import sys,json; print(json.load(sys.stdin)['txid'])")
SPK=$(bitcoin-cli -regtest decoderawtransaction "$SIGNED" | python3 -c "import sys,json; print(json.load(sys.stdin)['vout'][0]['scriptPubKey']['hex'])")
CAMT=$(python3 -c "print(f'{float($AMT) - 0.00010000:.8f}')")
RAWC=$(bitcoin-cli -regtest createrawtransaction "[{\"txid\":\"$PTXID\",\"vout\":0}]" "[{\"$A2\":$CAMT}]")
SIGC=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" signrawtransactionwithwallet "$RAWC" "[{\"txid\":\"$PTXID\",\"vout\":0,\"scriptPubKey\":\"$SPK\",\"amount\":$AMT}]" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
bitcoin-cli -regtest submitpackage "[\"$SIGNED\", \"$SIGC\"]" | python3 -c "import sys,json; print(json.load(sys.stdin)['package_msg'])"
```

Expected output (ids differ):

```text
TRUC-violation, non-version=3 tx 07eb1464... cannot spend from version=3 tx 3117e4d5...
```

The rule is enforced in `PackageTRUCChecks`
(`src/policy/truc_policy.cpp`). Mixed version packages cannot smuggle
an unbound child onto a TRUC parent.

### Step 5: Submit the valid package

```bash
./05-truc-package-relay-review/truc_1p1c_package.sh
```

Expected output (ids differ):

```json
{
  "package_msg": "success",
  "tx-results": {
    "5e9e2a462ad3c3b50d745ae96872a87c50400668e3581c3c218e0648431e8814": {
      "txid": "d0d9a3fe40afd149b4356fde7e0d2df918131f4bcaab6dbac66d98ec61a6eaf2",
      "vsize": 110,
      "fees": {
        "base": 0.00000000,
        "effective-feerate": 0.00045454
      }
    },
    "77980aaa69637fa25ec0c88b459fc026e12d4a1d6402b9ab6910347966df5733": {
      "txid": "677760bfe04e4784a6a56d558e7a10ae6642d464c4fc97521e24a694be1dacda",
      "vsize": 110,
      "fees": {
        "base": 0.00010000,
        "effective-feerate": 0.00045454
      }
    }
  }
}
```

Both entries share one effective feerate: 10,000 sats over 220 vB, or
0.00045454 BTC/kvB (45.45 sat/vB). The zero fee parent enters the
mempool atomically with its child. Neither could enter alone.

## Checkpoint

```bash
./lab.sh check 05
```

Expected output:

```text
PASS: stage 05. 1P1C package accepted; mixed version package rejected.
```

The check runs the Step 5 script and asserts `package_msg` is
`success`, then submits a mixed version package and asserts a
`TRUC-violation`. You can also rerun the script by hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `min relay fee not met, 0 < 110` | Zero fee parent sent alone (Step 3 does this on purpose) | Submit it as a package with a fee paying v3 child |
| `TRUC-violation, non-version=3 tx ...` | Child is not version 3 (Step 4 does this on purpose) | Flip the child version bytes to `03000000` as in Step 5 |
| `bad-txns-inputs-missingorspent` in `tx-results` | Child references a parent that failed validation | Fix the parent first; packages validate topologically |
| `list index out of range` in the script | No coin of at least 5 BTC | Mine more (`./lab.sh step 1`), then retry |

## Going further

1. Break the child size bound. Build a valid package, then pad the
   child above 1000 vB (add change outputs) and confirm
   `submitpackage` rejects it. Done when you see the size error.
2. Break the topology bound. Try a package with one parent and two
   children and read the rejection. Done when you can name which
   limit fired.
3. Read `PackageTRUCChecks`. Open `src/policy/truc_policy.cpp` and
   find the version inheritance check. Done when you can quote the
   error string.

## Contribution task

Pick one assertion in `test/functional/mempool_truc.py` and trace it
to the exact check in `src/policy/truc_policy.cpp` that it covers.
Write up the mapping (test line, source line, one sentence each) in a
lab docs issue so a future student can follow it. No upstream filing
needed.

## Sources

* BIP431 (Topology Restrictions for Pinning, Draft): the TRUC
  version 3 rules.
* `src/policy/truc_policy.h` and `src/policy/truc_policy.cpp`
  (`TRUC_VERSION`, `PackageTRUCChecks`).
* `test/functional/mempool_truc.py`: upstream test suite.
* `bitcoin-cli -regtest help submitpackage`: package RPC reference.
