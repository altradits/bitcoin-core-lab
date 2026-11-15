# Stage 01 Worksheet 4: Read a coinbase transaction byte by byte

**Output:** values in `my-work/01-node-foundations/answers.env`.
**Checker:** `./01-node-foundations/check_coinbase.sh` (same checker as Worksheet 3).

A coinbase transaction has exactly one input with a null prevout (txid all zeros, index
`0xffffffff`). Its `scriptSig` is free-form except for one rule.

## Part A — BIP34: the height in the coinbase
Since BIP34 the coinbase `scriptSig` must **start** with the block height, pushed as a minimally
encoded script number (little-endian, with a sign bit in the top bit of the last byte).

1. Look at the coinbase `scriptSig` of a few of your regtest blocks:
   `getblock <hash> 2` and read `tx[0].vin[0].coinbase`. Try heights 5, 17, 128 and 200.
   Write what you see in the journal and explain each one.
2. Decode these by hand (no RPC, no Python):

| Key | Coinbase scriptSig starts with | Decode the height |
|-----|-------------------------------|-------------------|
| `BIP34_HEIGHT_A` | `022c01` | ? |
| `BIP34_HEIGHT_B` | `03a0bb0d` | ? |
| `BIP34_HEIGHT_C` | `02800000` (ignore bytes after the height push) | ? |

3. Journal question: why does height 128 need **two** bytes in the push, when 128 fits in one byte?

<details><summary>Hint 1</summary>

The first byte is a push opcode: `0x01`..`0x4b` means "push the next N bytes". Heights 1..16 are
special: Core encodes them with `OP_1`..`OP_16` (bytes `0x51`..`0x60`).
</details>

<details><summary>Hint 2</summary>

Little-endian: the first data byte is the least significant. For the sign rule, read
`CScriptNum::serialize` in `src/script/script.h`.
</details>

## Part B — the witness commitment output
In a block with at least one segwit transaction, the coinbase has an extra output whose
`scriptPubKey` starts with a fixed 6-byte prefix followed by a 32-byte hash.

- Mine a block that contains a segwit transaction (send any payment between your wallets first).
- Find that output with `getblock <hash> 2`.
- Write `WITNESS_COMMITMENT_PREFIX=<the 6 bytes in hex>`.
- In the journal, name each of the 6 bytes (opcode, push length, magic) using BIP141's
  "Commitment structure" section and `GetWitnessCommitmentIndex` in `src/consensus/validation.h`.

<details><summary>Hint 1</summary>

`0x6a` is an opcode. Look it up in `src/script/script.h`.
</details>

## Part C — coinbase value rule
For the block in Part B, prove by hand that
`coinbase output total ≤ subsidy(height) + sum of fees in the block`.
Get the fees with `getblock <hash> 2` (each non-coinbase tx has a `fee` field) or `getblockstats`.
Write the block height as `COINBASE_CHECK_HEIGHT` and the total output value of its coinbase in
satoshis as `COINBASE_VALUE_SATS`. Then find the reject reason a block gets if it breaks the rule
(search `src/validation.cpp` for `bad-cb-amount`) and write it in the journal.
