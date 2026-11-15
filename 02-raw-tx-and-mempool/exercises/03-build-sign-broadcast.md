# Stage 02 Worksheet 3: Build, sign, test and broadcast a raw transaction

**Output:** a transaction on your node; answers in `answers.env` (section "Worksheet 3").
**Checker:** `./02-raw-tx-and-mempool/check_raw_tx.sh`

## The spec (a Kisumu point-of-sale payment)
- Exactly **one input**: one mature coinbase UTXO from `kisumu_miner`.
- Exactly **two outputs**: `1.00000000` BTC to a fresh `kisumu_merchant` address, and change to
  a fresh `kisumu_miner` **change** address.
- Fee: exactly **10,000 sat**.
- You test it with `testmempoolaccept` **before** you broadcast it.

Read the help of every RPC first: `listunspent`, `getnewaddress`, `getrawchangeaddress`,
`createrawtransaction`, `decoderawtransaction`, `signrawtransactionwithwallet`,
`testmempoolaccept`, `sendrawtransaction`, `getmempoolentry`, `getrawmempool`.

## Step 1 — the arithmetic, on paper first
Before you type `createrawtransaction`:
1. Write the input amount `I` (sat). Compute the change `C = I − 100,000,000 − 10,000`.
   Convert `C` to BTC with exactly 8 decimals. (A wrong decimal place is the most expensive bug in
   Bitcoin. Write the subtraction digit by digit.)
2. Predict this tx's `PREDICTED_WEIGHT` and `PREDICTED_VSIZE`. You decoded a transaction with the
   same shape in Worksheet 2; reason about which fields are fixed-size and which could vary by one
   byte (the DER signature).
3. Compute the feerate in sat/vB from your predicted vsize → `FEERATE_SAT_VB_RAW` (2 decimals).

<details><summary>Hint 1</summary>

P2WPKH input and outputs have fixed sizes except the signature, which is 71 or 72 bytes (low-R
signing in Core makes 71 the usual case — search `src/key.cpp` for `grind`).
</details>

## Step 2 — build and inspect
Create the unsigned tx. Decode it and check: one input, two outputs, values exactly as planned.
Note what `sequence` it got and why (read the `replaceable` argument of `createrawtransaction`).

<details><summary>Hint 1</summary>

`createrawtransaction` takes two JSON arrays. Quote them for the shell with single quotes, or build
them in shell variables. The output array is a list of one-key objects.
</details>

## Step 3 — sign, test, broadcast
Sign with the wallet that owns the input. Check `complete` is `true`. Run `testmempoolaccept`
and read every field it returns (`vsize`, `fees.base`, `fees.effective-feerate`). Compare with your
predictions **before** you broadcast. Then broadcast.

<details><summary>Hint 2 (which fields)</summary>

`testmempoolaccept` returns `fees.effective-feerate` in BTC/kvB. Convert: × 100,000,000 / 1,000 → sat/vB.
</details>

## Step 4 — look at it in the mempool
Use `getrawmempool` and `getmempoolentry`. Answer in the journal: what are `vsize`, `weight`,
`fees.base`, `fees.modified`, `ancestorcount`? Why is `modified` equal to `base` here?
(Look up `prioritisetransaction`.)

Write in `answers.env`:
`RAW_TXID`, `RAW_WTXID`, `PREDICTED_WEIGHT`, `PREDICTED_VSIZE`, `FEERATE_SAT_VB_RAW`.

## Step 5 — confirm it, and find it again
Mine one block. Then find your tx **in the block** with `getblock <hash> 2` and with
`getrawtransaction <txid> 1` (works thanks to `txindex=1` in your Stage 01 config). Write
`RAW_TX_BLOCK_HEIGHT`.

Journal question: the coinbase of that block pays `subsidy + 10,000 sat` (if your tx was alone).
Which Stage 01 rule makes that the maximum?
