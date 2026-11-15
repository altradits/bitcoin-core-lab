# Stage 11 Worksheet 2: Sync signet and read IBD

**Output:** journal entries. **Checker:** self-check (sync time depends on your network).

Run ONE node at a time on the 8 GB M1: stop your regtest node first.

1. Start `bitcoind` with your `signet.conf` (use `-conf=` and a separate `-datadir=`).
2. Every few minutes, record from `getblockchaininfo`: `blocks`, `headers`,
   `verificationprogress`, `initialblockdownload`, `size_on_disk`. Plot or tabulate them. Why
   does `headers` race ahead of `blocks` at the start?
3. Run `getpeerinfo` and record for 3 peers: `connection_type`, `transport_protocol_type`
   (v1 or v2 / BIP324), `synced_headers`, `synced_blocks`.
4. In `debug.log`, find the lines that show headers sync progress and the `UpdateTip` lines.
   What is logged per block?
5. Once synced, get free signet coins from a faucet (search "signet faucet"; check the URL
   carefully) to a fresh address of a new signet wallet. Track the incoming tx from mempool to
   1 confirmation.
6. Journal: in your own words, the life of a block from `headers` message to `UpdateTip`
   (Stage 14 and 15 will show you the code).
