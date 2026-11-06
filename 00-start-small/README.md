# Stage 00: Start small

You touch a live node in the first five minutes. You mine blocks, look
at your coins, send coins, run a small Go program, and read one real
bug fix. Everything runs on regtest, which is a local test chain with
worthless coins.

If a later stage feels hard, come back here and repeat these steps.

## Goal

After this stage you can start a node, mine blocks, list coins, send
coins, and run a Go program against the node.

## Why it matters

Bitcoin has no accounts table. The whitepaper (section 2) defines a
coin as a chain of signatures, and the network agrees on one history
of transfers (sections 3 to 5). Your wallet holds separate coins
(called UTXOs), and a transfer waits in the mempool before a miner
confirms it. These five steps show you each of those ideas on a live
node before you read any C++ code.

## Prerequisites

* Bitcoin Core v29.0 installed. See START_HERE.md for install steps.
* Go 1.22 or later.
* No earlier stage. This is the first one.

## Setup

Start the node and create the two wallets the lab reuses. The
`fallbackfee` flag lets wallet sends work on a fresh regtest chain,
which has no fee history to estimate from.

```bash
bitcoind -regtest -daemon -fallbackfee=0.00001
bitcoin-cli -regtest createwallet "kisumu_miner"
bitcoin-cli -regtest createwallet "kisumu_merchant"
```

Expected output:

```text
Bitcoin Core starting
{
  "name": "kisumu_miner"
}
{
  "name": "kisumu_merchant"
}
```

If a wallet already exists, `createwallet` prints `Wallet file
verification failed ... already exists`. That is fine. Continue.

## Steps

### Step 1: Mine your first blocks

```bash
./lab.sh step 1
```

Expected output (heights differ on your machine; the genesis hash is
always the same on regtest):

```text
1. Block #0 (Genesis Hash) : 0f9188f13cb7b2c71f2a335e3a4fc328bf5beb436012afca590b1a11466e2206
2. Height Before Mining    : 0
3. Height After Mining 101 : 101
```

Block 0 is the hard coded first block. Mining 101 blocks gives you one
mature coin to spend. New coins wait 100 blocks before they can move.
Stage 01 explains why.

### Step 2: Look at your coins

```bash
./lab.sh step 2
```

Expected output (txids differ on your machine):

```text
Here are the top 3 digital coins currently inside your 'kisumu_miner' wallet:
  Coin #1: Amount = 50.0 BTC | txid = 83765efe4321a7d60d8f3df2... (vout 0)
```

Each line is one UTXO: an amount plus the transaction output it came
from. Your balance is the sum of these coins. There is no accounts
table.

### Step 3: Send coins and watch the mempool

```bash
./lab.sh step 3
```

Expected output (addresses and txids differ on your machine):

```text
1. Fresh Merchant Address  : bcrt1q2kcfufajxy8nh0auq6jmrej8zyqqa9nfghfvg4
2. Sent 0.50 BTC! TXID     : e53ed4581dcd024d647dc1fe31cf8360cd368951efd964a9aeeaff16360dd54a
3. Waiting in Mempool Now  : 1 unconfirmed transaction(s)

4. Mined 1 Block! Mempool  : 0 unconfirmed transaction(s) (Confirmed!)
```

A send has two phases. First the transaction waits in the mempool.
Then a mined block confirms it and the mempool drains.

### Step 4: Run your first Bitcoin program

```bash
./lab.sh step 4
```

Expected output (values differ on your machine):

```text
[1] Live Blockchain Height : Block #270
[2] Miner Wallet Balance   : 7968.79019859 BTC
[3] New Bitcoin Address    : bcrt1qcrwynr20vek0v9tvrtfgnur8ch0k58w9agnffl (label: stanley_first_step)
[4] Sent 0.21 BTC! TXID    : e12b7f4110b2dba59ee141a89966574cb3db39df5dbedaf44539955e5309ffff
[5] Waiting in Mempool     : 0.21000000 BTC (unconfirmed)
[6] Mined 1 Block! Height  : Block #271
[7] Merchant Confirmed Bal : 6.41980000 BTC
```

This runs [first_app.go](./first_app.go), a short Go program that calls
`bitcoin-cli` six times. Open the file. Every Bitcoin app does the same
three things: ask the node for state, make an address, send coins.

### Step 5: Read one real bug fix

```bash
./lab.sh step 5
```

Expected output:

```text
Look at Mission 1 in 09-bug-dojo-and-pr-mastery/dojo_missions.go (lines 59-72):
	// 1. Check each output individually AND cumulative sum (CVE-2010-5139 defense)
	var nValueOut int64 = 0
	for _, txout := range tx.Vout {
		if txout.Value < 0 {
			return errors.New("bad-txns-vout-negative")
		}
		...
Running Mission 1 verification right now:
=== RUN   TestMission1_ConsensusShield_CVE2010_And_CVE2018
--- PASS: TestMission1_ConsensusShield_CVE2010_And_CVE2018 (0.00s)
```

In 2010 an attacker printed 184 billion BTC because the code added up
outputs before checking each one for negative values. Three checks
(each output, then the running total) stop that bug. Stage 09 lets you
reproduce it and write the fix yourself.

## Checkpoint

```bash
./lab.sh check 00
```

Expected output:

```text
PASS: stage 00. first_app.go sent coins and confirmed them.
```

The check runs `first_app.go` directly. You can also run it by hand:

```bash
go run ./00-start-small/first_app.go
```

It passes when line `[4]` shows a txid (not `Send failed`) and line
`[7]` shows a confirmed merchant balance above zero.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `Could not connect to the server 127.0.0.1:18443` | The node is not running | Run the `bitcoind` command from Setup, wait 5 seconds, retry |
| `Fee estimation failed. Fallbackfee is disabled.` | Fresh regtest has no fee history | Stop the node (`bitcoin-cli -regtest stop`), restart with `-fallbackfee=0.00001` |
| `[4] Send failed ...` from first_app.go | Miner wallet has no mature coins | Run `./lab.sh step 1` (mines 101 blocks), then retry |
| `Wallet file verification failed ... already exists` | Wallet was created before | Ignore it and continue |
| `No such file or directory: bitcoin-cli` | Binaries are not on PATH | Add your build dir, for example `export PATH="$HOME/bitcoin/build/bin:$PATH"` |

## Going further

1. Edit `myProjectLabel` in first_app.go to your own name, run
   `./lab.sh step 4` again, and confirm line `[3]` shows your label.
2. Change `amountBTC` from `"0.21"` to another value, rerun, and
   confirm line `[4]` and the merchant balance match the new amount.
3. Print one more node fact. Add a line that prints
   `askBitcoin("getmempoolinfo")` and rerun.

## Contribution task

Read one page of the Bitcoin Core RPC docs (`bitcoin-cli -regtest
help getblockcount`) and check that this stage quotes its behavior
correctly. If you find a mistake in this stage, open a lab bug issue
with the exact step and output. See CONTRIBUTING.md.

## Sources

* Satoshi Nakamoto, Bitcoin whitepaper, sections 2 (Transactions) and
  5 (Network). Link in offline-library/OFFLINE_INDEX.md.
* Bitcoin Core `doc/build-osx.md` and `doc/build-unix.md`: how to
  install `bitcoind` and `bitcoin-cli`.
* `bitcoin-cli -regtest help`: every RPC used here
  (`generatetoaddress`, `getbalance`, `sendtoaddress`,
  `getmempoolinfo`).
