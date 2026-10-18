# Stage 00: Start Small — The 15-Minute Micro-Win Ladder

> *"Every Bitcoin Core maintainer started by not knowing what a UTXO or a raw hex byte was. You do not master Bitcoin by trying to swallow all 300,000 lines of C++ in one day. You master it by touching the live node for 15 minutes a day, changing one thing, and watching what happens."*

If Stages 01–10 ever feel heavy or overwhelming, **stop and come right here to `00-start-small/`**.

This folder is designed so you **never give up**. Every step takes **5 to 15 minutes**, touches your **live `bitcoind` node**, and gives you an immediate win.

---

## The Golden Rule When Things Feel Hard

1. **Never read code without touching the live node first.** Bitcoin is a living machine running on your laptop right now. When you see a strange word (`UTXO`, `mempool`, `txid`, `vbytes`), run a single command to *see* it with your own eyes.
2. **Shrink the problem to 15 minutes.** Do **one** micro-step per day. Commit that one small win with `./lab.sh commit-offline "Completed Micro-Step X"`. Momentum beats intensity.
3. **Move from CLI -> Tiny Script -> Single Function -> Full Stage.**

---

## The 5 Micro-Steps (Run `./lab.sh step <1..5>`)

You can run each of these steps interactively from the root of the repo:

### Micro-Step 1 (5 Minutes): Touch Satoshi's Block #0 & Mine 1 Block
Run:
```bash
./lab.sh step 1
```
**What you learn:** A blockchain is just a stack of numbered boxes (blocks). Block `0` is Satoshi's Genesis Block. When you mine a block on regtest, you add 1 new box to the top of the stack.

### Micro-Step 2 (10 Minutes): See Your Digital Coins (`UTXOs`)
Run:
```bash
./lab.sh step 2
```
**What you learn:** Bitcoin does not store "account balances" like a bank database. Instead, your wallet holds individual digital coins called **UTXOs** (*Unspent Transaction Outputs*), just like physical gold coins of different sizes in a pouch.

### Micro-Step 3 (10 Minutes): Send Bitcoin & Watch the Waiting Room (`Mempool`)
Run:
```bash
./lab.sh step 3
```
**What you learn:** When you send Bitcoin, it doesn't go straight into a block. First, it waits in the **Mempool** (the transaction waiting room). Once a miner mines 1 block, your transaction moves from the waiting room into the permanent blockchain.

### Micro-Step 4 (15 Minutes): Run & Edit Your First 60-Line Bitcoin Program
Run:
```bash
./lab.sh step 4
```
Then open [`first_app.go`](file:///Users/mac/bitcoin-core-lab/00-start-small/first_app.go) in this folder. It is only 60 lines of simple Go code.
**Your 3 Tiny Builder Wins:**
1. Open [`first_app.go`](file:///Users/mac/bitcoin-core-lab/00-start-small/first_app.go) and change `myProjectLabel` on line 39 to your own name. Run `go run first_app.go`.
2. Change `amountBTC` on line 44 from `"0.21"` to `"1.337"`. Run `go run first_app.go` and watch your live merchant balance jump by `1.337 BTC`.
3. Add one extra `fmt.Println` that prints `askBitcoin("getmempoolinfo")` so you can see your node's memory usage.

### Micro-Step 5 (15 Minutes): Fix Just ONE 3-Line Bug in the Dojo
Run:
```bash
./lab.sh step 5
```
Instead of worrying about all 5 missions in Stage 09, focus on **Mission 1 only**:
- Why did `CVE-2010-5139` happen? Because Satoshi forgot to check `if out < 0`!
- Adding a 3-line check (`if out < 0 || out > MaxMoney`) stops the biggest bug in Bitcoin's history.

---

## How to Graduate at Your Own Pace

Once `00-start-small/` feels easy and natural:
- Move to **Stage 01** (`./lab.sh practice 01`) — spend a whole day just playing with `COINBASE_MATURITY`.
- Move to **Stage 02** (`./lab.sh practice 02`) — spend a whole day building 1 raw transaction by hand.
- Move to **Stage 09 Mission 1** (`./lab.sh dojo check 1`) — fix one bug at a time.
