# Stage 01: Node basics

You run `bitcoind` on regtest, create a wallet, mine blocks, and watch
new coins stay unspendable for exactly 100 blocks. You also verify that
the regtest block subsidy halves every 150 blocks.

## Goal

After this stage you can explain coinbase maturity and the halving
schedule, and point to the C++ code that enforces them.

## Why it matters

The whitepaper (section 6) pays miners with new coins, but a miner
that spends those coins at once would break everyone downstream if its
block loses a chain race. Unlike normal transactions, a coinbase has no
parent to return to the mempool, so consensus forces a 100 block wait
(`COINBASE_MATURITY`). The halving schedule caps supply at 21 million
BTC. On regtest the interval is 150 blocks instead of 210,000 so you
can watch a halving happen in seconds.

## Prerequisites

* Stage 00 (a running node, the `kisumu_miner` wallet).
* A Bitcoin Core source checkout to read the quoted files (optional
  but recommended). The lab default is `~/bitcoin`.

## Setup

Load the lab wallets. If the node is not running, start it as in
Stage 00 with `-fallbackfee=0.00001`.

```bash
bitcoin-cli -regtest loadwallet "kisumu_miner"
bitcoin-cli -regtest getblockcount
```

Expected output:

```text
{
  "name": "kisumu_miner"
}
101
```

Your height differs if you mined more blocks. Any height works.

## Steps

### Step 1: Read the consensus constant

```bash
grep -n "COINBASE_MATURITY" ~/bitcoin/src/consensus/consensus.h | head -3
```

Expected output:

```text
19:static const int COINBASE_MATURITY = 100;
```

The comment above it says coinbase outputs can only be spent after
this many new blocks. This is a network rule, not a wallet policy.

### Step 2: Watch a coin mature

```bash
./01-node-foundations/verify_coinbase_maturity.sh
```

Expected output (addresses differ; amounts are 50 on a fresh chain
and halve every 150 blocks after that):

```text
Mining to Regtest Bech32 address: bcrt1qqt0a5nsjd3aqxq8hkpmxcnt3mz33lpyz6ejwda
[1/3] Mining initial coinbase block...
Spendable balance after 1 block: 0.00000000 (immature coin: 50.0)
[2/3] Mining 99 confirmation blocks (100 total, still 1 short of COINBASE_MATURITY=100)...
Spendable balance after 100 total blocks: 0.00000000
[3/3] Mining 100th confirmation block (101st total block)...
Spendable balance after 101 total blocks: 50.00000000
PASS: coinbase unspendable for 100 blocks, spendable after 101 (subsidy 50.0).
```

The script mines to a fresh wallet on every run, so these lines look
the same on any machine. The first coin becomes spendable only when
100 blocks sit on top of it. The amount equals the block subsidy at
your height (50 below height 150, 25 below 300, and so on). If pending
transactions sit in your mempool, the first block also collects their
fees, and the final line shows subsidy plus fees.

### Step 3: Read the enforcement code

The check lives in `Consensus::CheckTxInputs` in
`src/consensus/tx_verify.cpp`:

```cpp
// If prev is coinbase, check that it's matured
if (coin.IsCoinBase() && nSpendHeight - coin.nHeight < COINBASE_MATURITY) {
    return state.Invalid(TxValidationResult::TX_PREMATURE_SPEND, "bad-txns-premature-spend-of-coinbase",
        strprintf("tried to spend coinbase at depth %d", nSpendHeight - coin.nHeight));
}
```

Spend at depth 99 and the node rejects the transaction with
`bad-txns-premature-spend-of-coinbase`. Spend at depth 100 and it
passes.

### Step 4: Watch a halving

Regtest halves every 150 blocks (`CRegTestParams` in
`src/kernel/chainparams.cpp`, line 535):

```cpp
consensus.nSubsidyHalvingInterval = 150;
```

Mine past height 150 if you are below it, then compare the coinbase
value just below and above the boundary:

```bash
ADDR=$(bitcoin-cli -regtest -rpcwallet="kisumu_miner" getnewaddress)
bitcoin-cli -regtest generatetoaddress 60 "$ADDR" > /dev/null
for H in 149 150 151; do
  HB=$(bitcoin-cli -regtest getblockhash $H)
  echo -n "height $H subsidy: "
  bitcoin-cli -regtest getblock $HB 2 | python3 -c "import sys,json; print(json.load(sys.stdin)['tx'][0]['vout'][0]['value'])"
done
```

Expected output:

```text
height 149 subsidy: 50.0
height 150 subsidy: 25.0
height 151 subsidy: 25.0
```

Blocks 0 to 149 pay 50 BTC. Blocks 150 to 299 pay 25 BTC. The next
halving is at height 300.

## Checkpoint

```bash
./lab.sh check 01
```

Expected output:

```text
PASS: stage 01. coinbase matured after 100 blocks; regtest halves at height 150.
```

The check runs the script from Step 2 and asserts the three balances
(0, 0, then subsidy). You can also run the script directly as in
Step 2.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `Could not connect to the server` | Node is not running | Start it as in Stage 00 Setup |
| `Wallet kisumu_miner not found` | Wallet was never created | Run `bitcoin-cli -regtest createwallet "kisumu_miner"` |
| `Block height out of range` on `getblockhash 150` | Chain is shorter than 150 blocks | Mine more: `generatetoaddress 60` as in Step 4 |
| Many `stage01_run_*` wallets in the datadir | Each script run creates one wallet | Harmless on regtest. To reset, stop the node and delete the `regtest` datadir |

## Going further

1. Trigger the premature spend error by hand. Mine 1 block to a fresh
   address, build a transaction that spends that coinbase at once with
   `createrawtransaction`, and confirm `sendrawtransaction` fails with
   `bad-txns-premature-spend-of-coinbase`. Done when you see that
   exact string.
2. Find the mainnet interval. Open `src/kernel/chainparams.cpp` and
   find `nSubsidyHalvingInterval` for mainnet. Done when you can say
   its value (210,000) and the file line.
3. Check the subsidy math. Use `getblock` at heights 299 and 300 and
   confirm the second halving (25 to 12.5). Done when both values are
   on your screen.

## Contribution task

Run the upstream unit test that covers money ranges and report the
result. From your `bitcoin` checkout:

```bash
cmake --build build -j4 --target test_bitcoin
./build/bin/test_bitcoin --run_test=amount_tests
```

If it passes, you have verified consensus amount code on your machine.
If it fails, open a lab bug issue with the output. Do not file upstream
until a maintainer confirms the failure.

## Sources

* `src/consensus/consensus.h` (line 19): `COINBASE_MATURITY = 100`.
* `src/consensus/tx_verify.cpp` (`Consensus::CheckTxInputs`): the
  `bad-txns-premature-spend-of-coinbase` check.
* `src/kernel/chainparams.cpp` (`CRegTestParams`, line 535): regtest
  `nSubsidyHalvingInterval = 150`.
* Whitepaper section 6 (Incentive): why miners are paid in new coins.
