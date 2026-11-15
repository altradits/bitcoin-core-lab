# Stage 01 Worksheet 2: Your own start / stop procedure

**Output:** `my-work/01-node-foundations/node.sh` — a small Bash script **you** write.
From now on you use it instead of `00-start-small/setup_regtest.sh` and instead of letting
`lab.sh` start a node for you.
**Checker:** `./01-node-foundations/check_node_procedure.sh` (add `--cycle` to let it stop and
restart your node through your script).

## Required behaviour
| Command | Must do | Exit code |
|---------|---------|-----------|
| `node.sh start` | start `bitcoind` in the background with your datadir; wait until RPC answers; do nothing (and say so) if it already runs | 0 when RPC answers |
| `node.sh status` | print chain, block height and number of loaded wallets | 0 if running, non-zero if not |
| `node.sh stop` | stop the node *through RPC* (never `kill -9`) and wait until the process is gone | 0 |
| `node.sh log` | show the last 20 lines of the regtest `debug.log` | 0 |

Rules:
- The datadir must come from a variable at the top (`DATADIR=${DATADIR:-...}`) so the checker can
  point it elsewhere.
- Use `set -euo pipefail`. Quote your variables.
- Never start a second `bitcoind` if one is running (8 GB RAM).

<details><summary>Hint 1 (concept)</summary>

`bitcoind` can fork into the background by itself. It is "up" only when RPC answers, not when the
process exists: loading the block index and wallets takes a moment. Shutdown is also not instant;
the process flushes the UTXO cache to disk before it exits.
</details>

<details><summary>Hint 2 (which commands)</summary>

Look up `-daemon` and `-datadir` in `bitcoind -help`. For readiness, look at `help getblockchaininfo`
and at the `-rpcwait` option of `bitcoin-cli`. For stop, the RPC is literally named `stop`. To wait
for the process to exit, `pgrep -f` with your datadir path works on macOS. On regtest the log is
in a sub-folder of the datadir; find its name with `ls`.
</details>

## Questions for your journal
1. What is in the `.cookie` file, when is it created, and when is it deleted?
2. What happens to the mempool when you stop and start the node? (Look for `mempool.dat`, and the
   `-persistmempool` option.)
3. Why is `kill -9` dangerous for a node, and what does the node do on its next start after one?
