# Stage 00 — Self-check quiz answers (spoilers)

1. The **genesis block**. It is built by `CreateGenesisBlock(...)` in `src/kernel/chainparams.cpp`;
   each network's params class (for regtest: `CRegTestParams`) calls it with its own time/nonce.
2. Coinbase outputs mature after `COINBASE_MATURITY = 100` blocks (`src/consensus/consensus.h`).
   After 101 blocks only the coinbase of block 1 has 100 blocks on top of it, so 1 × 50 BTC is
   spendable; the other 100 × 50 BTC are `immature`.
3. In the node's **mempool**. Each node has its own mempool; nodes can disagree about what is in it
   (different policies, different arrival order, evictions).
4. Fee = sum of input values − sum of output values. Consensus computes it in
   `Consensus::CheckTxInputs` (`src/consensus/tx_verify.cpp`).
5. A fresh regtest node has no fee estimates and the wallet's fallback fee is 0 by default, so the
   wallet cannot pick a fee ("Fee estimation failed..."). Fix: pass `fee_rate` (sat/vB) to
   `sendtoaddress`, or set `fallbackfee=` in your `bitcoin.conf` (you will do that in Stage 01).
6. `getbalances` (the older `getbalance` returns only one number).
7. `bad-txns-vout-negative` (`src/consensus/tx_check.cpp`).

## Expected answers.env values
- `GENESIS_HASH` — whatever `getblockhash 0` prints on regtest (it is fixed for regtest).
- `SPENDABLE_UTXO_COUNT=1`
- `MY_FIRST_TXID` — your own txid.
