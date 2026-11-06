# Stage 11: Run a node on a small machine

You size a pruned mainnet node for limited disk and RAM, compare the
four networks, practice fee math across address types, and walk a
checklist for moving from a custodial wallet to your own node wallet.
Hands on work stays on regtest. Mainnet steps are read only planning
plus one optional signet sync.

## Goal

After this stage you can write a `bitcoin.conf` that fits your disk,
explain pruning, estimate fees by address type, and describe a safe
custodial to self custody move.

## Why it matters

Most students run small laptops, not servers. Pruning keeps a fully
validating node in a few GB by deleting old block files after
validation. The skills transfer directly: fee estimation by vByte,
UTXO hygiene, and descriptor wallets are the same on every network.
This stage connects the lab to the real world without risking real
money.

## Prerequisites

* Stage 07 (descriptor wallets; the live check reuses them).
* Go 1.22 or later.
* A running regtest node for the live check.

## Setup

```bash
go -C ./11-from-regtest-to-live-mainnet test ./...
```

Expected output:

```text
ok  	github.com/altradits/bitcoin-core-lab/11-from-regtest-to-live-mainnet	0.474s
```

## Steps

### Step 1: Run the unit tests verbosely

```bash
go -C ./11-from-regtest-to-live-mainnet test -v ./...
```

Expected output:

```text
--- PASS: TestAllBitcoinNetworksGraduationLadder (0.00s)
--- PASS: TestGenerateLaptopMainnetConfigM1Safety (0.00s)
--- PASS: TestEstimateTxVBytesFeeMinimization (0.00s)
ok
```

The tests pin the four networks (ports, address prefixes), the small
machine config values, and the fee math (226 vB legacy vs 141 vB
SegWit for 1 input 2 outputs).

### Step 2: Run the node sizing program

```bash
go -C ./11-from-regtest-to-live-mainnet run .
```

Expected output (descriptors and addresses differ):

```text
STAGE 11: SMALL MACHINE NODE, WALLET MIGRATION & FEE MATH
...
[1] SMALL MACHINE NODE PROFILE (EXAMPLE: 8 GB RAM, 60+ GB FREE DISK):
  • Node Mode         : Pruned Mainnet (-prune=5500 -dbcache=1024 -par=4)
  • Disk Footprint    : about 5.5 GB of block files plus the UTXO set database
...
[2] THE 4 BITCOIN NETWORKS BITCOIN CORE SUPPORTS:
  • 1. Regtest (Stage 00-10 Sandbox)       | Prefix: bcrt1... | Flag: -regtest
  • 2. Signet (BIP325 Global Test Network) | Prefix: tb1... | Flag: -signet
  • 3. Testnet4 (BIP94 Global PoW Testnet) | Prefix: tb1... | Flag: -testnet4
  • 4. Mainnet (Live Bitcoin)              | Prefix: bc1... | Flag: (none)
...
[3] FEE MATH (WHY ADDRESS TYPE AND UTXO COUNT MATTER):
  • 1-Input, 2-Output Legacy (1...)      : 226 vBytes (at 10 sat/vB = 2260 sats)
  • 1-Input, 2-Output Native SegWit(bc1q): 141 vBytes (at 10 sat/vB = 1410 sats, about 38% less)
  • 5-Input Consolidation SegWit (bc1q)  : 413 vBytes vs Taproot (bc1p): 384 vBytes
...
[4] LIVE WALLET CHECK ON THIS MACHINE (COLD SIGNER AND WATCH ONLY VAULT):
  • Public BIP84 Descriptor (no private keys):
    wpkh([61a93833/84h/1h/0h]tpubDDfbE8xyK5wcPXM5J9DMWTkinUBC82bhK9ndUVkuY1YvA34iUJDHXQSbSv83415BsSuZqL1BtrDpBoq1RBrCCQdd6B4YzpwLirshx9VuZda/0/*)#8l3mypq4
  • Watch Only Receiving Address : bcrt1q...
```

Section 1 sizes the node: `prune=5500` caps block files near 5500 MiB
(the minimum allowed is 550 MiB), `dbcache=1024` caps the UTXO cache
at 1 GB, `par=4` uses 4 validation threads. Section 4 repeats the
Stage 07 descriptor check on your live regtest node. If your node uses
a custom datadir, export `BITCOIN_CLI` first (same convention as
Stage 06).

### Step 3: Write your own bitcoin.conf (planning only)

Copy the generated config from `GenerateLaptopMainnetConfig` into a
draft file. Do not start mainnet yet. Read each line and answer:

1. Where does `prune=5500` store its data on your OS, and how much
   free disk remains after 5.5 GB plus the UTXO set?
2. What happens if you set `dbcache` above half your RAM?
3. Why is `walletrbf=1` useful when fees spike?

Done when you can answer all three without looking.

### Step 4 (optional): Sync signet and measure real disk use

Signet is small and syncs fast. Start it with a separate datadir so
regtest is untouched:

```bash
bitcoind -signet -datadir=/tmp/bitcoin-signet -daemon
sleep 30
bitcoin-cli -signet -datadir=/tmp/bitcoin-signet getblockchaininfo | python3 -c "import sys,json; b=json.load(sys.stdin); print('blocks:', b['blocks'], 'size_on_disk:', b.get('size_on_disk'))"
```

Expected output (numbers grow over time):

```text
blocks: 250000 size_on_disk: 900000000
```

This shows real `size_on_disk` accounting on a live network. Stop it
when done:

```bash
bitcoin-cli -signet -datadir=/tmp/bitcoin-signet stop
```

### Step 5: Migration checklist (read, do not run on mainnet yet)

Moving from a custodial wallet to your own node wallet:

1. Sync and verify. `verificationprogress` must read `0.9999` or
   higher in `getblockchaininfo` before you trust addresses.
2. Create an encrypted descriptor wallet with a passphrase stored on
   paper, never in a file or chat log.
3. Back up the wallet file and `listdescriptors` output to two
   separate offline media.
4. Generate one receiving address and confirm `getaddressinfo` shows
   `ismine: true` before sharing it.
5. Test with a small amount first, spend it once, restore from backup
   on a second machine if you can, then move the rest in as few
   UTXOs as possible during low fee periods.

Never paste seeds, passphrases, or private keys into the lab, issues,
or chat logs.

## Checkpoint

```bash
./lab.sh check 11
```

Expected output:

```text
PASS: stage 11. unit tests passed; live wallet check reached the node.
```

The check runs the unit tests plus the Step 2 program and requires
section 4 to print a descriptor. You can also rerun Steps 1 and 2 by
hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| Section 4 prints only the Note line | Node is down or `BITCOIN_CLI` unset for custom datadirs | Start the node; export `BITCOIN_CLI` |
| `Wallet not found` in section 4 | Stage 07 wallets missing | Run Stage 07 Step 2 first |
| Signet `Could not connect` | Daemon still starting | Wait 30 seconds and retry |
| `Prune mode is incompatible with -txindex` | Config conflict | Pruned nodes cannot serve the full transaction index; drop `-txindex` |

## Going further

1. Price your own wallet. List your regtest UTXOs, count inputs for a
   typical spend, and estimate its vBytes with `EstimateTxVBytes`.
   Done when your estimate is within 5 vB of a real `decoderawtransaction`.
2. Try assumeUTXO sync. Read `doc/` notes on assume valid snapshots
   and sync signet that way. Done when you can explain what security
   tradeoff it makes.
3. Measure dbcache effect. Sync signet twice with `dbcache=100` and
   `dbcache=1024` and compare wall time. Done when both numbers are
   on screen.

## Contribution task

Pick one `bitcoin.conf` option from this stage (`prune`, `dbcache`,
`par`, `maxconnections`) and check that its help text matches the
source in `src/init.cpp`. If the help text is unclear, propose better
wording in a lab docs issue with the exact lines. Upstream doc fixes
are welcome once a maintainer agrees.

## Sources

* `src/init.cpp` (`-prune` help: MiB target, minimum 550) and
  `src/validation.h` (`MIN_DISK_SPACE_FOR_BLOCK_FILES`).
* `doc/reduce-memory.md` and `doc/reduce-traffic.md` in
  bitcoin/bitcoin: small machine tuning.
* BIP325 (Signet) and BIP94 (Testnet4): the test networks.
* `bitcoin-cli -regtest help getblockchaininfo` (`size_on_disk`,
  `verificationprogress`).
