# Stage 02 Worksheet 1: Write your own lab setup

From this stage on **you** own the environment. No `setup_*.sh` helper is provided.

**Output:** `my-work/02-raw-tx-and-mempool/setup.sh`
**Checker:** `./02-raw-tx-and-mempool/check_setup.sh` (it runs your script once, then inspects the node)

## Required behaviour
Your script must be **idempotent** (running it twice changes nothing the second time, except that it
may mine more blocks if coins are short). After it runs:
1. the node is up (call your Stage 01 `node.sh start`, or start it yourself);
2. wallets `kisumu_miner` and `kisumu_merchant` are loaded — created if missing, loaded if they
   exist on disk but are not loaded, left alone if already loaded;
3. `kisumu_miner` has **at least 5 spendable (mature) UTXOs**; mine to it only as many blocks as
   needed;
4. it prints the height and both wallets' trusted balances.

Rules: `set -euo pipefail`; do not hide errors with `|| true` except where you can explain in a
comment why the error is expected; use `BTC_CLI` if it is set.

<details><summary>Hint 1 (concept)</summary>

"Already exists" and "already loaded" are different errors from different RPCs. Decide which state
the wallet is in *before* you act: one RPC lists loaded wallets, another lists wallets on disk.
</details>

<details><summary>Hint 2 (which RPCs)</summary>

`listwallets`, `listwalletdir`, `createwallet`, `loadwallet`, `listunspent` (count results),
`generatetoaddress`. In Bash, read a CLI command from the environment with
`read -r -a CLI <<< "${BTC_CLI:-bitcoin-cli -regtest}"` and call it as `"${CLI[@]}" getblockcount`.
How many blocks must you mine to get N mature coinbase outputs from a wallet that has none?
</details>
