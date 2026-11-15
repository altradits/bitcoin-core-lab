# Stage 01 Worksheet 3: Coinbase maturity and the subsidy schedule

**Output:** values in `my-work/01-node-foundations/answers.env`, a wallet named `maturity_lab`.
**Checker:** `./01-node-foundations/check_coinbase.sh`

Do every calculation **on paper first** (or in your journal), then confirm with an RPC.
Write both the hand result and the RPC result in the journal.

---

## Part A — subsidy arithmetic (by hand)

Read `GetBlockSubsidy` in `~/bitcoin/src/validation.cpp` and the
`nSubsidyHalvingInterval` values in `~/bitcoin/src/kernel/chainparams.cpp`
(mainnet and regtest are different). Note that the subsidy is in **satoshis** and that halving is a
right bit-shift.

Fill in (all values in satoshis, integers):

| Key | Question |
|-----|----------|
| `SUBSIDY_REGTEST_149` | subsidy of regtest block 149 |
| `SUBSIDY_REGTEST_150` | subsidy of regtest block 150 |
| `SUBSIDY_REGTEST_300` | subsidy of regtest block 300 |
| `SUBSIDY_MAINNET_840000` | subsidy of mainnet block 840,000 |
| `FIRST_ZERO_HALVING` | the smallest number of halvings after which `50 BTC >> halvings` is 0 sat |

<details><summary>Hint 1</summary>

halvings = height / interval (integer division). 50 BTC = 5,000,000,000 sat. Each halving divides
by 2 and drops the remainder.
</details>

<details><summary>Hint 2</summary>

For `FIRST_ZERO_HALVING`, find the highest power of two that is ≤ 5,000,000,000. Also read the
special case at the top of `GetBlockSubsidy` and explain in your journal why it exists
(think about what `x >> 64` does in C++).
</details>

---

## Part B — the UTXO set total (by hand, then RPC)

The genesis block's coinbase output is **not** in the UTXO set (it can never be spent; find the
reason in `src/validation.cpp`, search for "Special case for the genesis block"). Fees do not change the total:
they move from inputs into the next coinbase.

1. Read your current height `H` from the node.
2. By hand, compute the sum of the subsidies of blocks 1..H on regtest.
3. Write `UTXO_HEIGHT=H` and `UTXO_TOTAL_SATS=<your sum>`.
4. Confirm with `gettxoutsetinfo` (read its help; it can take a moment). If the numbers differ,
   write in the journal why (hint: did you ever create an `OP_RETURN` output with value, or leave a
   fee unclaimed?).

<details><summary>Hint 1</summary>

Split blocks 1..H into halving epochs: how many blocks in 1..149, in 150..299, and so on.
</details>

---

## Part C — the maturity experiment (predict, then observe)

1. Create a wallet `maturity_lab` and mine **exactly 1 block** to one of its addresses.
   Record that block's height as `CB_HEIGHT`. Record its coinbase txid as `CB_TXID`.
2. **Predict on paper** two heights:
   - `MEMPOOL_ACCEPT_TIP`: the lowest chain tip at which the node's mempool would accept a
     transaction spending that coinbase.
   - `WALLET_TRUSTED_TIP`: the lowest chain tip at which `getbalances` in `maturity_lab` shows the
     50 BTC (or current subsidy) as `trusted` instead of `immature`.
3. Mine blocks **to a different wallet** one step at a time near your predicted heights. At each
   tip, check `getbalances` and use `testmempoolaccept` on a signed transaction that spends the
   coinbase (build it with `createrawtransaction` + `signrawtransactionwithwallet`; you will
   master these in Stage 02). Record the exact reject reason you saw before maturity as
   `PREMATURE_REJECT_REASON`. Do **not** broadcast it.
4. If your two predictions were the same number but the node disagreed, find out why.

<details><summary>Hint 1 (concept)</summary>

Consensus checks a spend against the height of the block it would be mined in, not the current
tip. Read the coinbase check in `Consensus::CheckTxInputs` (`src/consensus/tx_verify.cpp`) and find
what `nSpendHeight` is when the mempool calls it (search `validation.cpp` for `CheckTxInputs(`).
</details>

<details><summary>Hint 2 (wallet side)</summary>

Search `src/wallet/wallet.cpp` for `COINBASE_MATURITY`. Compare the formula with the consensus one.
Which is more conservative, and by how many blocks?
</details>

There is no Hint 3. Run the experiment and let the node teach you.
