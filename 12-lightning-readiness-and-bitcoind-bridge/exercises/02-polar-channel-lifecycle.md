# Stage 12 Worksheet 2: Channel lifecycle in Polar, by `lncli` only

**Output:** `my-work/12-lightning-readiness-and-bitcoind-bridge/polar_journal.md` with every command
you typed and its key output. **Checker:** `./check_polar_journal.sh` (checks that the journal shows
each step; it cannot see your Polar network).

Use your Polar network (Docker running, your native `bitcoind` stopped). Find each node's gRPC
port, TLS cert and macaroon paths yourself from Polar's `docker-compose.yml` or the node's
"Connect" tab. Use `lncli --help` and `lncli <command> --help` for every command.

## Goals (in order)
1. **Identify:** for two LND nodes (A and D), record pubkey, alias, synced-to-chain status.
2. **Fund A on-chain:** get an on-chain address from A, send coins to it from the Polar backend
   `bitcoind` with `bitcoin-cli` (find its RPC port and credentials), mine enough blocks to confirm.
3. **Connect A → D** over P2P.
4. **Open a 1,000,000-sat channel A → D.** Find the funding txid and output index in lncli's
   output, then look up that tx on the backend with `getrawtransaction … true`. Record its
   output script type and why it is what it is.
5. **Confirm the channel** by mining the number of blocks lnd needs (find out how many).
6. **Invoice and pay:** D creates a 250,000-sat invoice; decode it with `lncli decodepayreq`
   **before** paying (record payee, amount, expiry, payment hash); A pays it.
7. **Check balances:** local/remote balance on both sides. Explain the numbers (reserve, commit fee, anchors).
8. **Close cooperatively** and find the closing tx on-chain. How many outputs, and why?

Write each heading in your journal as `## Step N` with the commands and outputs under it.
