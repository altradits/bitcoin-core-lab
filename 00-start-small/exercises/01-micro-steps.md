# Stage 00 Worksheet 1: The Five Micro-Steps (you type every command)

**Rules for this worksheet**
- Type every command yourself. Do not copy from `solutions/`.
- Before you use an RPC for the first time, read its help: `bitcoin-cli -regtest help <rpc>`.
- Save every command you typed, plus one line saying what you learned, in
  `my-work/00-start-small/journal.md` (create the folder: `mkdir -p my-work/00-start-small`).
- Copy `exercises/answers.env.template` to `my-work/00-start-small/answers.env` and fill it in as you go.
- When you finish, run `./00-start-small/check_micro_steps.sh` from the repo root.

> Note: if your node uses its own datadir, export `BTC_CLI` so the checker can reach it,
> e.g. `export BTC_CLI="bitcoin-cli -datadir=$HOME/regtest-lab"`. In this worksheet
> `bitcoin-cli -regtest` means "your CLI command".

Start a node first with `./00-start-small/setup_regtest.sh` (helper only, it creates nothing).

---

## Micro-Step 1 (5 min): Touch block 0, then mine

**Goal:** Print the hash of the genesis block (height 0) and the current block count.
Then create a wallet named `kisumu_miner`, get one address from it, and mine **101** blocks to that address.

**What to use:** `getblockhash`, `getblockcount`, `createwallet`, `getnewaddress`, `generatetoaddress`.

Write in `answers.env`: `GENESIS_HASH=` (the hash you saw).

<details><summary>Hint 1 (concept)</summary>

A chain is a list of blocks numbered from 0. Every network (mainnet, testnet, signet, regtest)
has its own hard-coded genesis block. Regtest's genesis is defined in `src/kernel/chainparams.cpp`
in the regtest params class (search for `CRegTestParams`).
</details>

<details><summary>Hint 2 (which RPCs and arguments)</summary>

`getblockhash` takes one number: the height. `generatetoaddress` takes *how many blocks* and then
*which address*. Wallet RPCs need `-rpcwallet=<name>` once more than one wallet is loaded.
</details>

**Why 101?** Write your answer in the journal before you move on. (You will prove it in Stage 01.)

---

## Micro-Step 2 (10 min): See your coins (UTXOs)

**Goal:** List the unspent outputs in `kisumu_miner`. Count how many there are, and explain why
there are not 101 of them even though you mined 101 blocks.

**What to use:** `listunspent`, `getbalances` (read both helps).

Write in `answers.env`: `SPENDABLE_UTXO_COUNT=` (the number of spendable UTXOs right after mining 101 blocks).

<details><summary>Hint 1 (concept)</summary>

A coinbase output cannot be spent until it is 100 blocks deep. A wallet only lists spendable
coins by default. Compare the `trusted` and `immature` fields of `getbalances`.
</details>

<details><summary>Hint 2</summary>

`listunspent` has optional arguments `minconf` and `maxconf`. You do not need them here; read the
default values in the help text and decide what they mean for the count.
</details>

---

## Micro-Step 3 (10 min): Send coins and watch the mempool

**Goal:**
1. Create a second wallet, `kisumu_merchant`, and get one address from it.
2. Send `0.5` BTC from `kisumu_miner` to that address.
3. *Before* mining, prove the transaction is in the mempool (two different RPCs show it).
4. Mine 1 block, then prove the mempool is empty and the merchant balance is confirmed.

**What to use:** `createwallet`, `getnewaddress`, `sendtoaddress`, `getrawmempool`, `getmempoolinfo`,
`generatetoaddress`, `getbalances`, `gettransaction`.

Write in `answers.env`: `MY_FIRST_TXID=` (the txid of your 0.5 BTC send).

<details><summary>Hint 1 (concept)</summary>

On a fresh regtest chain there is no fee history, so the wallet cannot estimate a fee. If you see
`Fee estimation failed`, the wallet is asking you to choose a fee rate yourself.
</details>

<details><summary>Hint 2 (which argument)</summary>

Read `help sendtoaddress` and find the argument that takes a rate in **sat/vB**. A value like 2 is
enough on regtest. You can pass arguments by name with `bitcoin-cli -named`.
</details>

---

## Micro-Step 4 (15 min): Write your first Bitcoin program

**Goal:** Copy `exercises/first_app.go` to `my-work/00-start-small/first_app.go` and replace every
`TODO(you)` with working Go code. The program must print the block height, the miner balance, a
new merchant address, the txid of a payment, and the height after mining one block.

Run it with `go run my-work/00-start-small/first_app.go`. Check it with
`./00-start-small/check_first_app.sh`.

<details><summary>Hint 1 (concept)</summary>

Your program does nothing new: it runs the same RPCs you typed in Steps 1–3, through
`os/exec`. Every app that talks to `bitcoind` is "call an RPC, read the answer, decide".
</details>

<details><summary>Hint 2 (which Go functions)</summary>

`exec.Command(name, args...)`, then `.Output()` or `.CombinedOutput()`, then `strings.TrimSpace`.
Wallet calls need the `-rpcwallet=<name>` argument before the RPC name.
</details>

---

## Micro-Step 5 (15 min): Read one consensus check

**Goal:** Open `/Users/mac/bitcoin/src/consensus/tx_check.cpp`. Find the loop that checks each
output value. In your journal, write in your own words:
1. Which two conditions make an output value invalid?
2. Which reject reason string does each one return?
3. Why must the *running total* of outputs also be checked, not only each output?

<details><summary>Hint 1</summary>

Look for `MoneyRange` and `MAX_MONEY`. `MAX_MONEY` is defined in `src/consensus/amount.h`.
</details>

<details><summary>Hint 2</summary>

Search for strings that start with `bad-txns-vout-`. Then think about two outputs that are each
under `MAX_MONEY` but add up to more.
</details>

Then try Stage 09 Mission 1 (`./lab.sh dojo check 1`) if you want to fix this check yourself.

---

## Done?

Run `./00-start-small/check_micro_steps.sh`. If it prints FAIL, read the reason, fix your work,
and run it again. Open `solutions/` only after the check passes or after 3 honest attempts.
