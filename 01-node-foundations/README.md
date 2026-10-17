# Hour 01: Bitcoin Core Daemon, Halving Epochs & Coinbase Maturity

## Objective
Run `bitcoind` v29.0 in `regtest` mode, initialize a native SegWit SQLite descriptor wallet (`kisumu_miner`), mine blocks via `generatetoaddress`, and verify consensus enforcement of `COINBASE_MATURITY` and `nSubsidyHalvingInterval` against the C++ implementation.

---

## 1. Upstream C++ Consensus References

### Coinbase Maturity (`src/consensus/consensus.h`)
```cpp
/** Coinbase transaction outputs can only be spent after this number of new blocks (network rule) */
static constexpr int COINBASE_MATURITY = 100;
```

### Coinbase Spend Validation (`src/consensus/tx_verify.cpp`)
In `Consensus::CheckTxInputs`, if an input spends a coinbase output, the node enforces:
```cpp
if (coin.IsCoinBase() && nSpendHeight - coin.nHeight < COINBASE_MATURITY) {
    return state.Invalid(TxValidationResult::TX_PREMATURE_SPEND, "bad-txns-premature-spend-of-coinbase",
        strprintf("tried to spend coinbase at depth %d", nSpendHeight - coin.nHeight));
}
```
**Protocol Rationale:** Unlike regular transactions that return to the mempool during a chain reorganization, coinbase transactions exist solely within the block that mined them. Requiring 100 confirmations prevents orphaned blocks from invalidating downstream recipient transactions across the network.

### Regtest Halving Interval (`src/kernel/chainparams.cpp`)
```cpp
consensus.nSubsidyHalvingInterval = 150;
```
- **Blocks 0–149:** `50.00000000 BTC`
- **Blocks 150–299:** `25.00000000 BTC`
- **Blocks 300–449:** `12.50000000 BTC`

---

## 2. Execution & Empirical Verification

### Step 1: Start Daemon & Create Descriptor Wallet
```bash
./build/bin/bitcoind -regtest -daemon
./build/bin/bitcoin-cli -regtest createwallet "kisumu_miner"
ADDR=$(./build/bin/bitcoin-cli -regtest -rpcwallet="kisumu_miner" getnewaddress)
# Output: bcrt1qc6pf0w3cft6xc8t3z7fm50astl2mnenaxhuxn3
```

### Step 2: Mine Initial Block (Height 203)
```bash
./build/bin/bitcoin-cli -regtest generatetoaddress 1 $ADDR
# Block Hash: 76b1f8047fe4272bdbd143e341659c16cfaaeea969058c4e916a248ef8179d8d
```
Wallet state at **1 confirmation** (Height 203, 2nd Halving Epoch):
```json
{
  "walletname": "kisumu_miner",
  "format": "sqlite",
  "balance": 0.00000000,
  "immature_balance": 25.00000000,
  "txcount": 1,
  "descriptors": true,
  "lastprocessedblock": {
    "hash": "76b1f8047fe4272bdbd143e341659c16cfaaeea969058c4e916a248ef8179d8d",
    "height": 203
  }
}
```

### Step 3: Boundary Test at 99 Additional Blocks (Height 302)
Mining 99 blocks on top of block 203 crosses the height-300 halving boundary (`25 BTC -> 12.5 BTC`) while keeping block 203's coinbase output 1 block short of maturity (`302 - 203 = 99 < 100`):
```bash
./build/bin/bitcoin-cli -regtest generatetoaddress 99 $ADDR
./build/bin/bitcoin-cli -regtest -rpcwallet="kisumu_miner" getwalletinfo
```
```json
{
  "balance": 0.00000000,
  "immature_balance": 2462.50000000,
  "txcount": 100,
  "lastprocessedblock": {
    "hash": "5ee4fbef3ccebcfe25e06042af075adc0a5d76e564540d1cad0f084a29dfff39",
    "height": 302
  }
}
```
*(Math check: `97 blocks × 25 BTC + 3 blocks × 12.5 BTC = 2462.50000000 BTC` immature)*

### Step 4: Mine the 100th Confirmation Block (Height 303)
```bash
./build/bin/bitcoin-cli -regtest generatetoaddress 1 $ADDR
./build/bin/bitcoin-cli -regtest -rpcwallet="kisumu_miner" getwalletinfo
```
```json
{
  "balance": 25.00000000,
  "immature_balance": 2450.00000000,
  "txcount": 101,
  "lastprocessedblock": {
    "hash": "1e20d1a7615f595e1b6495c39d3f2e2525d2d3315e14d4557c14ec58e549e016",
    "height": 303
  }
}
```

### Step 5: Verify Matured UTXO in `listunspent`
```json
[
  {
    "txid": "93328febe1e73e7d3bbb8dc9256fc57ae704d883b5538919a44c821ef957a29a",
    "vout": 0,
    "address": "bcrt1qc6pf0w3cft6xc8t3z7fm50astl2mnenaxhuxn3",
    "scriptPubKey": "0014c68297ba384af46c1d711793ba3fb05fd5b9e67d",
    "amount": 25.00000000,
    "confirmations": 101,
    "spendable": true,
    "solvable": true,
    "desc": "wpkh([bf59251b/84h/1h/0h/0/0]03e5e984e15d364d2dba11671dbdb9c24a2ff1f23cc15b2de3af3344221e764bcf)#5mw23ezc"
  }
]
```
Notice `scriptPubKey: 0014c68297ba384af46c1d711793ba3fb05fd5b9e67d`:
- `00`: Witness Version 0 (`OP_0`)
- `14`: Push 20 bytes (`0x14 = 20`)
- `c68297ba384af46c1d711793ba3fb05fd5b9e67d`: `HASH160(compressed_pubkey)` (P2WPKH)
