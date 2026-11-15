# Stage 07: Descriptors and offline signing

You split a wallet in two: a watch only coordinator that holds public
descriptors but no keys, and an offline signer that holds the keys but
never sees the network. The coordinator builds an unsigned PSBT, the
signer signs it, and the coordinator broadcasts the result.

## Goal

After this stage you can export BIP84 descriptors, build a PSBT on a
watch only wallet, sign it offline, and finalize it.

## Why it matters

BIP380 output descriptors describe exactly which addresses belong to a
wallet, so a coordinator can watch balances and build transactions
without keys. BIP174 (PSBT) is the portable format that carries an
unsigned transaction to the signer and back. Hardware wallets, vaults,
and multisig setups all use this split. The demo mirrors it with two
local wallets standing in for the two machines.

## Prerequisites

* Stage 02 (transactions and fees).
* Go 1.22 or later.
* A running node with `kisumu_miner` funded (Stage 00), started with
  `-fallbackfee=0.00001` so fee estimation works.

## Setup

```bash
go -C ./07-psbt-descriptors-and-miniscript test ./...
```

Expected output:

```text
ok  	github.com/altradits/bitcoin-core-lab/07-psbt-descriptors-and-miniscript	0.677s
```

This runs the offline unit tests only. No node needed.

If your node uses a custom datadir or RPC port, export overrides
before the live run in Step 2 (defaults fit a standard install):

```bash
export BITCOIND_RPC_URL="http://127.0.0.1:18443"
export BITCOIN_COOKIE="$HOME/Library/Application Support/Bitcoin/regtest/.cookie"
```

## Steps

### Step 1: Run the unit tests verbosely

```bash
go -C ./07-psbt-descriptors-and-miniscript test -v ./...
```

Expected output:

```text
=== RUN   TestValidateBIP174Header
--- PASS: TestValidateBIP174Header (0.00s)
=== RUN   TestValidateSatsOutputConsensusBounds
--- PASS: TestValidateSatsOutputConsensusBounds (0.00s)
=== RUN   TestRPCBaseURLDefaultAndOverride
--- PASS: TestRPCBaseURLDefaultAndOverride (0.00s)
=== RUN   TestLoadRegtestAuthExplicitCookie
--- PASS: TestLoadRegtestAuthExplicitCookie (0.00s)
PASS
```

The tests cover the PSBT magic header (`psbt\xff`, base64 `cHNidP8`),
the dust and MAX_MONEY bounds, and the RPC connection helpers.

### Step 2: Run the live signing flow

```bash
go -C ./07-psbt-descriptors-and-miniscript run .
```

Expected output (descriptors, addresses, and txids differ):

```text
1. Exported & Imported Public BIP84 Descriptor:
   wpkh([61a93833/84h/1h/0h]tpubDDfbE8xyK5wcPXM5J9DMWTkinUBC82bhK9ndUVkuY1YvA34iUJDHXQSbSv83415BsSuZqL1BtrDpBoq1RBrCCQdd6B4YzpwLirshx9VuZda/0/*)#8l3mypq4
2. Watch-Only Derived Vault Address: bcrt1qr0trl5tj8zpjn347fzs6kyc0sc5rpjvwj6mqlk
3. Funded Vault UTXO (0.50000000 BTC) in TXID: f5962b7e07f95822fd96c0abcc75a3aba03f4cc7d9e62bf39ae4fbf13e336c8b
4. Watch-Only Created Unsigned BIP174 PSBT (395 bytes, Fee=0.00000141 BTC):
   Prefix: cHNidP8BAHECAAAAAUbYcPgZMSruOGP5OwWEbRvHVB5DFckD...
5. Cold Signer Processed PSBT (Complete=true)
6. Finalized & Broadcast Settlement TXID: 0ea732a96717ce3cd0160a185cf15f656b0af9cd1ac960fd7b59b2c27e84cfc7
```

What each line proves:

1. The signer wallet exports public `wpkh(...)` descriptors (note the
   `#8l3mypq4` checksum) and the watch only wallet imports them with
   `disable_private_keys` set.
2. The watch only wallet derives a fresh `bcrt1q` address with no
   keys on disk.
3. The miner funds the vault with 0.5 BTC.
4. The watch only wallet builds an unsigned PSBT paying 0.25 BTC.
   The base64 prefix `cHNidP8` decodes to the 5 magic bytes
   `0x70736274ff` (`psbt\xff`). The fee line shows the coin selected
   rate, 141 sats here.
5. The signer adds its signature across the airgap
   (`walletprocesspsbt`). `Complete=true` means every input signed.
6. `finalizepsbt` assembles the witness and `sendrawtransaction`
   broadcasts.

### Step 3: Confirm the broadcast settled

```bash
bitcoin-cli -regtest getrawmempool | head -3
bitcoin-cli -regtest -rpcwallet="kisumu_merchant" getbalance
```

Expected output: the mempool is empty (the program mines a
confirmation block at the end) and the merchant balance rose by
0.25 BTC from before the run.

## Checkpoint

```bash
./lab.sh check 07
```

Expected output:

```text
PASS: stage 07. unit tests passed; PSBT signed offline and broadcast.
```

The check runs the unit tests plus the Step 2 program and requires
`Complete=true` and a broadcast txid. You can also rerun Step 2 by
hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `regtest .cookie or bitcoin.conf credentials not found` | Node uses a custom datadir | Export `BITCOIN_COOKIE` as in Setup |
| `rpc error -4: Fee estimation failed` | Node started without `-fallbackfee` | Restart with `-fallbackfee=0.00001` (see Stage 00) |
| `rpc error -18: Wallet not found` | `kisumu_miner` or `kisumu_merchant` missing | Create them as in Stage 00 Setup |
| `Complete=false` after signing | Signer lacks a needed key (wrong descriptors) | Delete both `sovereign_*` wallets and rerun from scratch |
| `connection refused` on 127.0.0.1:18443 | Node is down or on another port | Start the node; export `BITCOIND_RPC_URL` if the port differs |

## Going further

1. Inspect the PSBT by hand. Copy the base64 from a run, decode the
   first bytes with `python3 -c`, and confirm they are
   `70736274ff`. Done when you see the magic bytes.
2. Tamper and watch finalization fail. Flip one character in the
   unsigned PSBT and pass it to `walletprocesspsbt`. Done when you
   can explain the error.
3. Read the descriptor checksum code. Open
   `src/script/descriptor.cpp` and find the checksum function. Done
   when you can say which checksum algorithm it uses (BCH polymod).

## Contribution task

Run the upstream PSBT functional test and confirm it passes:

```bash
python3 "$BITCOIN_ROOT/build/test/functional/test_runner.py" rpc_psbt.py
```

Expected: `rpc_psbt.py | Passed`. If it fails, open a lab bug issue
with the output. Do not file upstream until a maintainer confirms.

## Sources

* BIP174 (Partially Signed Bitcoin Transaction): roles and format.
* BIP380 (Output Script Descriptors) and BIP84 (BIP32 derivation for
  P2WPKH): the `wpkh(...)` strings.
* `src/psbt.h` (`PSBT_MAGIC_BYTES`) and `src/script/descriptor.cpp`.
* `bitcoin-cli -regtest help walletcreatefundedpsbt`: coordinator RPC.
