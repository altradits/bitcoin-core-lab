# Stage 01 Worksheet 1: Write your own `bitcoin.conf`

**Output:** `my-work/01-node-foundations/bitcoin.conf`, written by you, line by line.
**Checker:** `./01-node-foundations/check_conf.sh`

Every option you write must be one you looked up. Do not paste a config from the internet.
Your references:
- `bitcoind -help` (all options; pipe to `less` and search with `/`)
- `/Users/mac/bitcoin/doc/bitcoin-conf.md` (file format, sections, location)
- `/Users/mac/bitcoin/src/init.cpp` (where most options are registered with `AddArg`)

## Why a separate regtest datadir?
In Stage 11 you will run a real (pruned) mainnet node. Keep regtest in its own folder, for
example `$HOME/regtest-lab`, so the two never share wallets, ports or a config file.
On macOS the *default* datadir is `~/Library/Application Support/Bitcoin`; check this claim in
`doc/bitcoin-conf.md` or `doc/files.md` before you rely on it.

---

## Task 1 — choose the network and the sections
**Goal:** The node must run on regtest when started with only `-datadir=...` (no `-regtest` flag).
Some options are *network-only*: if they sit in the top (default) section of the file while you run
regtest, `bitcoind` refuses to start. Find out which options those are and put them in the right section.

<details><summary>Hint 1 (concept)</summary>

The file has a default section and per-network sections like `[main]`, `[test]`, `[signet]`,
`[regtest]`. Read the "Network specific options" part of `doc/bitcoin-conf.md`.
</details>

<details><summary>Hint 2 (where in the source)</summary>

In `src/init.cpp` and `src/wallet/init.cpp`, search for `ArgsManager::NETWORK_ONLY`. Then search
`init.cpp` for the error text `only applied on` to see what happens if you get it wrong.
</details>

## Task 2 — RPC and authentication
**Goal:** `bitcoin-cli` can talk to the node, and **no plain-text password** is in the file.
Write in your journal which of the two safe methods you chose and why.

<details><summary>Hint 1</summary>

If you set no RPC credentials at all, `bitcoind` writes a random `.cookie` file in the datadir
and `bitcoin-cli` reads it. The other method stores only a salted HMAC of the password.
</details>

<details><summary>Hint 2</summary>

Look at `-rpcauth` in `bitcoind -help` and at `/Users/mac/bitcoin/share/rpcauth/README.md`.
</details>

## Task 3 — options the next stages need
**Goal:** Add options so that:
1. the wallet can send on a fresh chain without you passing a fee rate every time;
2. `getrawtransaction` can find *any* confirmed transaction by txid (you will need this in Stages 02–03);
3. the node uses little RAM (this machine has 8 GB): set a small UTXO cache and a small mempool.

Write a `#` comment above each line explaining it in your own words, with its unit.

<details><summary>Hint 1</summary>

Option names to look up in `bitcoind -help`: a fee "fallback", a transaction "index", the database
cache, the maximum mempool size.
</details>

<details><summary>Hint 2</summary>

The fallback fee is given in **BTC/kvB**, not sat/vB. Convert by hand: 1 sat/vB = ? BTC/kvB.
Write the conversion in your journal. Read `-dbcache` and `-maxmempool` units (MiB / MB) in the help text.
</details>

## Task 4 — install it
Create your datadir, put the file there as `bitcoin.conf` (copy or symlink from `my-work/`), and
start the node with only the `-datadir` argument (plus `-daemon` if you like). Prove it is regtest
with one RPC. Then:

```
export BTC_CLI="bitcoin-cli -datadir=$HOME/regtest-lab"   # adjust to your path
```
Add that line to your shell profile so every checker in this lab reaches your node.

Break it on purpose once: move `rpcport=` to the top section, try to start, and copy the exact error
line from the terminal (or the end of `regtest/debug.log`) into your journal. Then fix it.

Run `./01-node-foundations/check_conf.sh`.
