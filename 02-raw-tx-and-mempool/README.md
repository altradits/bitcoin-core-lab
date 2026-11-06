# Stage 02: Raw transactions and mempool

You spend a coin by hand with the low level RPCs: build the bytes,
sign them, send them. You learn that a transaction has no fee field
(the fee is inputs minus outputs), that forgetting change triggers a
fee guardrail, and how SegWit weight math works.

## Goal

After this stage you can build, sign, and broadcast a raw SegWit
transaction and read its weight, fee, and mempool entry.

## Why it matters

Wallets hide transaction building, but contributors debug it. Consensus
computes the miner fee as `nValueIn - value_out` in
`Consensus::CheckTxInputs` (`src/consensus/tx_verify.cpp`). There is no
`fee` field to set. BIP141 (SegWit) moved signatures to the witness so
the txid no longer changes when a signature changes. That fix is what
lets Lightning chain unconfirmed transactions safely.

## Prerequisites

* Stage 00 (a running node with mature coins in `kisumu_miner`).
* Stage 01 (you know what a mature coin is).

## Setup

Confirm the miner wallet has at least one spendable coin:

```bash
bitcoin-cli -regtest -rpcwallet="kisumu_miner" getbalance
```

Expected output (any positive value works):

```text
50.00000000
```

If the balance is zero, run `./lab.sh step 1` and wait for 101 blocks.

## Steps

### Step 1: Send a proper transaction with change

```bash
./02-raw-tx-and-mempool/raw_tx_mempool.sh
```

Expected output (ids and addresses differ on your machine):

```text
Spending UTXO 1d190e14d59525f7ddb61d1858096f1e93795a67e0d667c1ca709d41849cfd11:0 (50.0 BTC)
 -> 1.00000000 BTC to bcrt1qujj42d8hjmpu4u5a324zwcsynw3cp9gr2wdry7
 -> 48.99990000 BTC change to bcrt1qtqz3zm7harckx6juj0t2gsv3qvlsf2n906v0fs (0.00010000 BTC fee)
Broadcasted TXID: 0c90064a94bd41822f7feee77b231f92f7fc1aa03722d6ac8fce1764f8ed9758
```

The script picks a miner coin, pays 1 BTC to the merchant, returns the
rest to a fresh change address, and leaves 0.0001 BTC (10,000 sats) as
the miner fee. Keep the printed TXID. The next steps use it.

### Step 2: Spring the fee trap (no change output)

Spend a different coin and pay 1 BTC with no change output. The missing
49 BTC silently becomes the fee, and the node refuses to broadcast:

```bash
UTXO=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" listunspent | python3 -c "import sys,json; u=[x for x in json.load(sys.stdin) if x['amount']>=2.0][0]; print(u['txid'], u['vout'])")
read TXID VOUT <<< "$UTXO"
MADDR=$(bitcoin-cli -regtest -rpcwallet="kisumu_merchant" getnewaddress)
RAW=$(bitcoin-cli -regtest createrawtransaction "[{\"txid\":\"$TXID\",\"vout\":$VOUT}]" "[{\"$MADDR\":1.0}]")
SIGNED=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" signrawtransactionwithwallet "$RAW" | python3 -c "import sys,json; print(json.load(sys.stdin)['hex'])")
bitcoin-cli -regtest sendrawtransaction "$SIGNED"
```

Expected output:

```text
error code: -25
error message:
Fee exceeds maximum configured by user (e.g. -maxtxfee, maxfeerate)
```

The wallet meant to pay 1 BTC but offered about 49 BTC as fee. The
`maxfeerate` guardrail (default 0.10 BTC/kvB on `sendrawtransaction`)
stops the broadcast before the transaction reaches the network. Real
money has been lost this way. Always check your change output.

### Step 3: Decode the transaction from Step 1

Rebuild and decode a signed 1 input, 2 output transaction to see where
the fee and signatures live:

```bash
TXID=$(bitcoin-cli -regtest getrawmempool | python3 -c "import sys,json; print(json.load(sys.stdin)[0])")
bitcoin-cli -regtest getrawtransaction "$TXID" true
```

Expected output (abbreviated; hashes differ on your machine):

```json
{
  "txid": "2cd98ec18b1c68f535dacb8570df2e96ae11e8767082c12474009853f29ac591",
  "hash": "084c383b3d994ea8951647a3c7d00d877fa63fca9cf8130e8fef365717daf03e",
  "version": 2,
  "size": 222,
  "vsize": 141,
  "weight": 561,
  "vin": [
    {
      "scriptSig": { "asm": "", "hex": "" },
      "txinwitness": ["30440220...", "03d8f427..."],
      "sequence": 4294967293
    }
  ]
}
```

Three things to notice. First, `scriptSig` is empty and the signature
plus public key sit in `txinwitness`. Second, `txid` and `hash`
(`wtxid`) differ, because the txid excludes witness data. Forging a new
signature changes the wtxid but not the txid. Third, `sequence` is
4294967293 (0xfffffffd), which signals BIP125 replaceability. Stage 03
uses that.

Weight math: base size 113 bytes, total size 222 bytes.
`weight = 113 * 3 + 222 = 561`, `vsize = ceil(561 / 4) = 141`.

### Step 4: Inspect the mempool entry

```bash
TXID=$(bitcoin-cli -regtest getrawmempool | python3 -c "import sys,json; print(json.load(sys.stdin)[0])")
bitcoin-cli -regtest getmempoolentry "$TXID"
```

Expected output (abbreviated):

```json
{
  "vsize": 141,
  "weight": 561,
  "fees": {
    "base": 0.00010000
  },
  "bip125-replaceable": true
}
```

The mempool agrees with the decode: 141 vB, 0.0001 BTC fee,
replaceable.

### Step 5: Confirm the block and check the miner got paid

```bash
ADDR=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" getnewaddress)
bitcoin-cli -regtest generatetoaddress 1 "$ADDR" > /dev/null
H=$(bitcoin-cli -regtest getblockcount)
bitcoin-cli -regtest getblock $(bitcoin-cli -regtest getblockhash $H) 2 | python3 -c "
import sys, json
cb = json.load(sys.stdin)['tx'][0]
for o in cb['vout']:
    print(o['value'], o['scriptPubKey'].get('type'), o['scriptPubKey'].get('hex', '')[:16])
"
```

Expected output (subsidy 50, 25, or 12.5 depending on your height;
plus the 0.0001 fee):

```text
25.00010000 witness_v0_keyhash 00147243346bae72
0.0 nulldata 6a24aa21a9ed5b6b
```

Output 0 pays the miner the block subsidy plus your exact fee.
Output 1 is the BIP141 witness commitment (`OP_RETURN` starting with
`aa21a9ed`), which anchors all SegWit signatures in the block.

## Checkpoint

```bash
./lab.sh check 02
```

Expected output:

```text
PASS: stage 02. raw tx confirmed; coinbase collected subsidy plus fee.
```

The check sends one raw transaction, mines a block, and asserts the
coinbase value equals subsidy plus fee. You can also rerun the script
from Step 1 and confirm it prints a new TXID.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `Fee exceeds maximum configured by user` | Missing change output (Step 2 does this on purpose) | Add a change output as in Step 1 |
| `list index out of range` from the python one liner | No coin of the needed size | Mine more: `./lab.sh step 1`, then retry |
| `Transaction not in mempool` on `getmempoolentry` | You already mined a block since the send | Resend with the Step 1 script, then inspect before mining |
| `insufficient fee` on `sendrawtransaction` | Fee below relay minimum | Raise the fee to at least 141 sats for a 141 vB tx |

## Going further

1. Pay an exact fee rate. Rebuild the Step 1 transaction with a
   282 sat fee (2.0 sat/vB for 141 vB) and confirm `getmempoolentry`
   shows `0.00000282`. Done when the fee field matches.
2. Make the transaction non replaceable. Pass `"sequence": 4294967295`
   in `createrawtransaction` and confirm `bip125-replaceable` is
   `false`. Done when the flag flips.
3. Read the fee code. Open `src/consensus/tx_verify.cpp` around
   `txfee_aux` and find where `bad-txns-in-belowout` triggers. Done
   when you can quote both lines.

## Contribution task

Run the upstream mempool package test and confirm it passes on your
machine:

```bash
python3 ~/bitcoin/build/test/functional/test_runner.py mempool_packages.py
```

Expected: `mempool_packages.py | Passed`. If it fails, open a lab bug
issue with the full output. Do not file upstream until a maintainer
confirms.

## Sources

* `src/consensus/tx_verify.cpp` (`Consensus::CheckTxInputs`,
  `txfee_aux = nValueIn - value_out`): implicit fees.
* `src/rpc/rawtransaction_util.cpp` (default `nSequence =
  MAX_BIP125_RBF_SEQUENCE`): why new transactions signal RBF.
* BIP141 (Segregated Witness): weight, vsize, witness commitment.
* BIP125 (Replace by Fee): the `sequence` signal, used in Stage 03.
