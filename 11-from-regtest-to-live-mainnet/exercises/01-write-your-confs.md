# Stage 11 Worksheet 1: Write your own signet and mainnet `bitcoin.conf`

**Output:** `my-work/11-from-regtest-to-live-mainnet/signet.conf` and `mainnet.conf`.
**Checker:** `./11-from-regtest-to-live-mainnet/check_confs.sh` (reads the files; starts nothing)

Read `bitcoind -help` (or `bitcoind -help-debug`) and `doc/bitcoin-conf.md` in your Core checkout
for every option before you use it. Write a comment line above each setting saying why it is there.

## Requirements for `mainnet.conf`
1. Runs as a server for `bitcoin-cli`, **in the background**.
2. Pruned: block files capped between the minimum allowed and 10,000 MiB.
3. UTXO cache of at least 450 MiB and at most 2,048 MiB (8 GB machine).
4. No transaction index (find out why it would refuse to start).
5. RPC reachable **only** from this machine, with **cookie** authentication — no `rpcpassword`
   and no `rpcuser` in the file.
6. At most 40 connections.
7. No option that is already the default just for show (e.g. do not set `walletrbf`).

## Requirements for `signet.conf`
1. Selects signet **in the file** (find the option that does this).
2. Uses a **section** so the network-specific settings only apply to signet.
3. Keeps a transaction index (signet is small, and you will look up txs while reviewing).
4. Same RPC safety rules as mainnet.

<details><summary>Hint 1 (sections)</summary>

`doc/bitcoin-conf.md` explains `[main]`, `[test]`, `[testnet4]`, `[signet]`, `[regtest]` sections and
which options are only valid inside them.
</details>
<details><summary>Hint 2 (RPC binding)</summary>

Two separate options control where RPC listens and who may connect. Look for `rpcbind` and
`rpcallowip`; with neither set, Core already listens on localhost only — the checker accepts
either an explicit localhost binding or no binding options at all.
</details>
