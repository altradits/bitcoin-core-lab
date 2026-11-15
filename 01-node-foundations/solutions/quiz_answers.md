# Stage 01 — quiz answers and worked answers (spoilers)

## Quiz
1. Any four of `port rpcport bind rpcbind addnode connect wallet walletdir`. In the top section,
   while running regtest, `bitcoind` stops with "Config setting for -X only applied on regtest
   network when in [regtest] section." (`src/init.cpp`).
2. A user name `__cookie__` and a random password, `__cookie__:<hex>`. Written at start-up,
   deleted at clean shutdown (`src/rpc/request.cpp`, `GenerateAuthCookie` / `DeleteAuthCookie`).
3. 1,250,000,000 sat (12.5 BTC): 300 // 150 = 2 halvings, 5,000,000,000 >> 2.
4. Mempool: tip 599 (the spend would be in block 600, and 600 − 500 = 100). Wallet: tip 600
   (depth 101, because `GetTxBlocksToMaturity` uses `COINBASE_MATURITY + 1`).
5. `ConnectBlock` returns early for the genesis block ("Special case for the genesis block,
   skipping connection of its transactions"), so its output never enters the UTXO set.
6. Push of 3 bytes `a0 bb 0d` little-endian → 0x0dbba0 = 900,000.
7. `ConnectBlock`: `block.vtx[0]->GetValueOut() > blockReward` → `bad-cb-amount`.
8. Halving = integer division by 2, which is a right shift on an integer number of satoshis. In
   C++, shifting a 64-bit value by 64 or more is undefined behaviour, so `GetBlockSubsidy`
   returns 0 when halvings ≥ 64.
9. An index from txid to block position, so `getrawtransaction <txid>` works for any confirmed
   tx without the `blockhash` argument. Without it, the RPC only finds mempool txs (and wallet
   txs via `gettransaction`).

## Worked answers for answers.env
- `SUBSIDY_REGTEST_149=5000000000`, `SUBSIDY_REGTEST_150=2500000000`,
  `SUBSIDY_REGTEST_300=1250000000`, `SUBSIDY_MAINNET_840000=312500000` (840000/210000 = 4).
- `FIRST_ZERO_HALVING=33`: 2^32 = 4,294,967,296 ≤ 5e9 < 2^33, so 5e9 >> 32 = 1 sat and 5e9 >> 33 = 0.
- `UTXO_TOTAL_SATS` for height H on regtest = 149 × 50 BTC (blocks 1..149) + 150 × 25 BTC (150..299)
  + 150 × 12.5 BTC (300..449) + ... up to H. Example: H = 307 → 7450 + 3750 + 8 × 12.5 = 11,300 BTC.
  (Verified on a v29.0 regtest node: `gettxoutsetinfo` → `total_amount` 11300.00000000 at height 307.)
- `MEMPOOL_ACCEPT_TIP = CB_HEIGHT + 99`, `WALLET_TRUSTED_TIP = CB_HEIGHT + 100`
  (measured on v29.0: coinbase at 105; `testmempoolaccept` rejected at tip 203, accepted at 204;
  `getbalances` immature at 204, trusted at 205).
- `PREMATURE_REJECT_REASON=bad-txns-premature-spend-of-coinbase`
- `BIP34_HEIGHT_A=300` (`02 2c01` → 0x012c), `BIP34_HEIGHT_B=900000`,
  `BIP34_HEIGHT_C=128` (`02 8000`: 0x80 alone would set the sign bit and mean −0, so a `00` byte is
  added; see `CScriptNum::serialize`).
- `WITNESS_COMMITMENT_PREFIX=6a24aa21a9ed`: `6a` = `OP_RETURN`, `24` = push 36 bytes,
  `aa21a9ed` = commitment header, then the 32-byte commitment.
