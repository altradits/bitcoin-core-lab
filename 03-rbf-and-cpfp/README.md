# Stage 03: Fee bumps with RBF and CPFP

You verify the two ways to rescue a stuck transaction. First you
replace a low fee transaction with a higher fee one (BIP125 RBF),
including one replacement the node rejects for paying too little extra.
Then you attach a high fee child to an unconfirmed parent (CPFP) and
watch the miner confirm both in dependency order.

## Goal

After this stage you can fee bump with RBF and CPFP, read ancestor
package feerates, and explain the anti spam rules that limit
replacement.

## Why it matters

Wallets and Lightning nodes must react when fees spike. BIP125 lets a
sender replace an unconfirmed transaction with a costlier version, and
CPFP lets a receiver (or anyone) pull a parent into a block by paying
for the package. Without the Rule 3 and Rule 4 checks in
`src/policy/rbf.cpp`, an attacker could force the network to relay
endless free replacements. Lightning anchor outputs depend on exactly
this package logic.

## Prerequisites

* Stage 02 (you can build raw transactions; the scripts reuse the same
  wallets).
* Mature coins in `kisumu_miner`. The script needs one coin of at
  least 5 BTC.

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

### Step 1: Broadcast a low fee RBF transaction

The script in Step 3 runs the whole flow at once. First, walk the RBF
part by hand so you see the rejection. Pick a miner coin and send 2 BTC
to the merchant with a 200 sat fee and RBF signaling sequence
(4294967293):

```bash
UTXO=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" listunspent | python3 -c "import sys,json; u=[x for x in json.load(sys.stdin) if x['amount']>=5.0][0]; print(u['txid'], u['vout'], u['amount'])")
read TXID VOUT AMT <<< "$UTXO"
MADDR=$(bitcoin-cli -regtest -rpcwallet="kisumu_merchant" getnewaddress)
CHG=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" getrawchangeaddress bech32)
CHG1=$(python3 -c "print(f'{float($AMT) - 2.0 - 0.00000200:.8f}')")
RAW1=$(bitcoin-cli -regtest createrawtransaction "[{\"txid\":\"$TXID\",\"vout\":$VOUT,\"sequence\":4294967293}]" "[{\"$MADDR\":2.0},{\"$CHG\":$CHG1}]")
SIG1=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" signrawtransactionwithwallet "$RAW1" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
TXID_V1=$(bitcoin-cli -regtest sendrawtransaction "$SIG1")
echo "TXID_V1=$TXID_V1"
bitcoin-cli -regtest getmempoolentry "$TXID_V1" | python3 -c "import sys,json; e=json.load(sys.stdin); print('vsize:', e['vsize'], 'fee:', e['fees']['base'], 'rbf:', e['bip125-replaceable'])"
```

Expected output (txid differs):

```text
TXID_V1=c684300cc1392ef802822237b3d30c6a2b1fdeaefc8ee44cbe4a2e047e89d4c6
vsize: 141 fee: 2e-06 rbf: True
```

The transaction pays 200 sats (0.00000200 BTC) for 141 vB, about
1.4 sat/vB, and signals replaceable.

### Step 2: Trigger the Rule 4 rejection

Try to replace it with a version paying only 50 sats more. Relay rules
require the replacement to pay for its own bandwidth
(`incrementalrelayfee`, 1 sat/vB, so at least 141 sats extra for a
141 vB transaction):

```bash
CHGB=$(python3 -c "print(f'{float($AMT) - 2.0 - 0.00000250:.8f}')")
RAWB=$(bitcoin-cli -regtest createrawtransaction "[{\"txid\":\"$TXID\",\"vout\":$VOUT,\"sequence\":4294967293}]" "[{\"$MADDR\":2.0},{\"$CHG\":$CHGB}]")
SIGB=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" signrawtransactionwithwallet "$RAWB" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
bitcoin-cli -regtest sendrawtransaction "$SIGB"
```

Expected output (txid differs):

```text
error code: -26
error message:
insufficient fee, rejecting replacement 66908efc2144457f30e99d00f6b94fe3fe215ddab05b6329bf5738fcc0829d00, not enough additional fees to relay; 0.0000005 < 0.00000141
```

This is Rule 4 in `PaysForRBF` (`src/policy/rbf.cpp`): the extra
0.00000050 BTC is below the 0.00000141 BTC relay cost of a 141 vB
replacement, so the node rejects it as a cheap relay spam attempt.

### Step 3: Run the full RBF plus CPFP script

```bash
./03-rbf-and-cpfp/rbf_and_cpfp.sh
```

Expected output (txids differ):

```text
[1/3] Broadcasted low-fee RBF parent TX_V1: d06ef0e2f2b47d6a5496794c7d85a2734ffa56ddd83a2f852b33843c04d029e0
[2/3] Replaced TX_V1 via BIP125 RBF with TX_V2: 5c58535a51ed87b1a4f597e76df2890083f2c57ea6f704add48f075294f53583
[3/3] Attached high-fee CPFP child TX_CHILD: fbe125852efdb76619f9015f9da14538c94083ebdb09e12e82c8dd1d170e2a1e
```

The script repeats Steps 1 and 2 on a fresh coin, then replaces with a
valid 5,000 sat version (4,800 sats extra, above the 141 sat floor) and
attaches a 20,000 sat child that spends the merchant output. The child
entry it prints ends with:

```json
{
  "vsize": 110,
  "weight": 437,
  "ancestorcount": 2,
  "ancestorsize": 251,
  "fees": {
    "base": 0.00020000,
    "ancestor": 0.00025000
  }
}
```

Package math: parent 5,000 sats over 141 vB plus child 20,000 sats
over 110 vB gives 25,000 sats over 251 vB, or 99.60 sat/vB. The miner
prices the package, not the parent alone.

### Step 4: Confirm the package in order

```bash
TX_CHILD=$(bitcoin-cli -regtest getrawmempool | python3 -c "import sys,json; print(json.load(sys.stdin)[-1])")
PARENT=$(bitcoin-cli -regtest getmempoolentry "$TX_CHILD" | python3 -c "import sys,json; print(json.load(sys.stdin)['depends'][0])")
ADDR=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" getnewaddress)
bitcoin-cli -regtest generatetoaddress 1 "$ADDR" > /dev/null
H=$(bitcoin-cli -regtest getblockcount)
bitcoin-cli -regtest getblock $(bitcoin-cli -regtest getblockhash $H) 1 | python3 -c "import sys,json; print(json.load(sys.stdin)['tx'])"
echo "parent was: $PARENT"
echo "child was: $TX_CHILD"
```

Expected output: the block lists three transactions, coinbase first,
then the parent, then the child:

```text
["50f287491c200f3c0b665686e48f1a516befd3e6846f592c3ffc1dba69808f46", "5c58535a51ed87b1a4f597e76df2890083f2c57ea6f704add48f075294f53583", "fbe125852efdb76619f9015f9da14538c94083ebdb09e12e82c8dd1d170e2a1e"]
parent was: 5c58535a51ed87b1a4f597e76df2890083f2c57ea6f704add48f075294f53583
child was: fbe125852efdb76619f9015f9da14538c94083ebdb09e12e82c8dd1d170e2a1e
```

Compare the last two lines with positions 1 and 2 of the block. The
miner (`BlockAssembler::addPackageTxs` in `src/node/miner.cpp`) orders
by dependency: a child can never confirm before its parent.

## Checkpoint

```bash
./lab.sh check 03
```

Expected output:

```text
PASS: stage 03. RBF replaced the parent; CPFP package confirmed in order.
```

The check runs the Step 3 script, mines one block, and asserts the
block holds parent then child. You can also rerun the script and Step 4
by hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `not enough additional fees to relay` | Replacement adds less than the relay cost (Step 2 does this on purpose) | Raise the fee so the extra covers 1 sat per vB of the replacement |
| `rejecting replacement ... less fees than conflicting txs` | Replacement pays less total than the original (Rule 3) | Never lower the total fee in a replacement |
| `Transaction not in mempool` for TX_V1 | It was already replaced | That is the expected state after Step 3; inspect TX_V2 instead |
| `list index out of range` in Step 1 | No coin of at least 5 BTC | Mine more (`./lab.sh step 1`), then retry |
| `missing inputs` on the child send | Wrong parent vout | The merchant output is vout 0 of TX_V2; recheck with `getrawtransaction` |

## Going further

1. Find the exact Rule 4 floor. Replace TX_V1 with exactly 141 sats
   extra and confirm it is accepted, then try 140 sats extra and
   confirm it is rejected. Done when both results are on screen.
2. Watch eviction over P2P. This needs two nodes, which Stage 04 sets
   up. After Stage 04, broadcast TX_V1, sync mempools, replace, sync
   again, and show TX_V1 gone from both nodes.
3. Read `PaysForRBF` in full. Open `src/policy/rbf.cpp` and find Rule 3
   above Rule 4. Done when you can state both rules in one sentence
   each.

## Contribution task

Run the upstream RBF functional test on your machine:

```bash
python3 ~/bitcoin/build/test/functional/test_runner.py feature_rbf.py
```

Expected: `feature_rbf.py | Passed`. If it fails, open a lab bug issue
with the full output. Do not file upstream until a maintainer confirms.

## Sources

* `src/policy/rbf.cpp` (`PaysForRBF`, Rules 3 and 4) and
  `src/util/rbf.h` (`MAX_BIP125_RBF_SEQUENCE`).
* `src/node/miner.cpp` (`BlockAssembler::addPackageTxs`): ancestor
  feerate package selection.
* BIP125 (Opt in Replace by Fee): signaling and the six replacement
  rules.
* `doc/policy/mempool-replacements.md` in bitcoin/bitcoin:
  replacement policy notes.
