# Stage 00: Start Small — The 15-Minute Micro-Win Ladder

> Every Bitcoin Core maintainer once did not know what a UTXO or a raw hex byte was. You learn
> Bitcoin by touching a live node for 15 minutes a day, changing one thing, and watching what happens.

If a later stage feels heavy, come back here. Every step takes 5–15 minutes and ends in a small win.

**How this stage works (the No-Shortcuts Rule).** You type every command. The worksheets tell you
*what* to achieve and *which* RPC to read about; they never give the finished command. Hints come
in two layers inside `<details>` blocks. Checkers look at your node and your files and print
PASS/FAIL. Reference answers live in [`solutions/`](./solutions/) — open them only after a check
passes or after **3 honest attempts**.

---

## Objectives (competency IDs)

| ID | You can... |
|----|------------|
| C-TX-2 (intro) | create a wallet, get an address, send a payment and read balances with RPCs you typed |
| C-CONS-1 (intro) | explain why fresh coinbase coins are not spendable, and find a consensus check in `src/consensus/` with its reject reason |
| C-MEMPOOL-1 (intro) | show a transaction waiting in the mempool and leaving it when mined |
| C-GIT-1 (intro) | keep the lab clone clean: your work lives in `my-work/`, so `git status` stays readable |

(IDs are defined in [`../CURRICULUM.md`](../CURRICULUM.md).)

## Prerequisites
- `bitcoind` and `bitcoin-cli` v29.0 on your `PATH` (`bitcoind -version`).
- Go installed (`go version`) for Micro-Step 4.
- Nothing else. This is the entry point.

---

## Theory in five paragraphs

**Blocks.** A blockchain is a list of blocks numbered from 0. Block 0 (the genesis block) is
hard-coded in `src/kernel/chainparams.cpp`. On **regtest** you create blocks on demand with
`generatetoaddress`, so you control time.

**UTXOs, not accounts.** Bitcoin has no balances in the protocol. It has *unspent transaction
outputs* (UTXOs): each one is an amount locked by a script. A wallet "balance" is the wallet adding
up the UTXOs it can unlock. A transaction destroys some UTXOs (its inputs) and creates new ones
(its outputs).

**Coinbase.** The first transaction in every block creates new coins (the subsidy) plus the fees of
the block. Consensus forbids spending a coinbase output until it is 100 blocks deep
(`COINBASE_MATURITY` in `src/consensus/consensus.h`). That is why you mine 101 blocks before you can
spend anything.

**Mempool.** A new transaction is checked by your node and kept in memory (the mempool) until a
miner puts it into a block. The mempool is *your node's view*, not a global object.

**Fees are implicit.** No transaction field says "fee". Fee = sum(inputs) − sum(outputs). On a fresh
regtest chain the wallet has no fee history, so you must choose a fee rate (sat/vB) yourself.

---

## Exercises

| # | Worksheet | Checker |
|---|-----------|---------|
| 1–3, 5 | [`exercises/01-micro-steps.md`](./exercises/01-micro-steps.md) | `./00-start-small/check_micro_steps.sh` |
| 4 | [`exercises/first_app.go`](./exercises/first_app.go) (skeleton with `TODO(you)`) | `./00-start-small/check_first_app.sh` |

Set-up helper (environment only, allowed by the conventions): [`setup_regtest.sh`](./setup_regtest.sh)
starts a node; it does not create wallets or blocks.

Your work goes in `my-work/00-start-small/`:
- `journal.md` — every command you typed and one line on what you learned.
- `answers.env` — copied from [`exercises/answers.env.template`](./exercises/answers.env.template).
- `first_app.go` — your finished program.

If your node uses its own datadir, export `BTC_CLI` (for example
`export BTC_CLI="bitcoin-cli -datadir=$HOME/regtest-lab"`) so the checkers can reach it.

---

## Checkpoint

```bash
./lab.sh check 00
```

Runs: ./check_micro_steps.sh, ./check_first_app.sh. Each prints PASS/FAIL with a reason, never the answer.
Open `solutions/` only after this passes or after three honest attempts.

## Self-check quiz (answer from memory, then compare with [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))
1. What is block 0 called, and where in the Bitcoin Core source is it defined?
2. Why does a wallet show 50 BTC spendable (not 5050 BTC) after you mine 101 blocks?
3. Where does a transaction wait between broadcast and confirmation? Is it the same on every node?
4. There is no `fee` field in a transaction. How is the fee determined?
5. Why might `sendtoaddress` fail on a brand-new regtest node, and what is one fix?
6. Which RPC shows `trusted`, `untrusted_pending` and `immature` balances?
7. Name the consensus reject reason for a negative output value.

## Review lens
When a `bitcoin/bitcoin` PR touches wallet sending or RPC help text, a reviewer who has done this
stage can at least:
- run the changed RPC on regtest by hand before and after the change, and paste the observed
  behaviour into a review (this is what "tested ACK" rests on);
- check that any change to coinbase or amount checks keeps `src/consensus/tx_check.cpp` and
  `src/consensus/tx_verify.cpp` consistent (`MoneyRange`, `COINBASE_MATURITY`);
- read `test/functional/wallet_basic.py` and `mempool_spend_coinbase.py` to see how the same
  behaviours are tested upstream.

## Proof-of-work output
Your `my-work/00-start-small/journal.md` and a working `first_app.go` you wrote. Optional public
artifact: a short gist "My first regtest session" written in your own words.

## Next
Stage 01 ([`../01-node-foundations/README.md`](../01-node-foundations/README.md)): you write your own
`bitcoin.conf` and start/stop procedure and replace `setup_regtest.sh` for good.
