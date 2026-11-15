# Stage 14 Exercise 1: Two regtest nodes you configure yourself

**Output:** two running nodes, a journal, and `my-work/14-p2p-and-net-processing/nodes.env`.
**Checker:** `./14-p2p-and-net-processing/check_14.sh nodes`

Stop every other `bitcoind` first (8 GB rule). Keep caches small.

## Step 1 — two datadirs, two configs
Write `nodeA.conf` and `nodeB.conf` yourself (under `my-work/14-p2p-and-net-processing/`). Each
needs: regtest, its **own** P2P and RPC ports, a small `dbcache`, `-debug=net` logging, and
**no** automatic outbound connections (find the option that disables DNS seeds and fixed
seeds — regtest has none anyway — and think about `-listen`). Node B must listen; node A must not
need to.

Record in `nodes.env`:
```
NODE_A_CLI=bitcoin-cli -datadir=<A datadir>
NODE_B_CLI=bitcoin-cli -datadir=<B datadir>
```

## Step 2 — connect A → B as a block-relay-only peer
Use the RPC that adds a node **with a chosen connection type** (`help addconnection` — note it is
a hidden/test RPC on regtest; read why in `src/rpc/net.cpp`). Then on both nodes run
`getpeerinfo` and record `connection_type`, `relaytxes`, `transport_protocol_type`,
`addr_relay_enabled` for the peer.

## Step 3 — add a second, full-relay connection
Connect A → B again as `outbound-full-relay`. Compare the two peer entries. Send a transaction
from a wallet on A and check, with `getpeerinfo`'s byte counters (`bytessent_per_msg`), which
connection carried `inv`/`tx` messages.

## Step 4 — read the log
In B's `debug.log` find: the `version` received, the `wtxidrelay`/`sendaddrv2` lines (if
logged), `verack`, and the moment the connection type was set. Paste 10–20 relevant lines in
your journal and annotate them.

## Step 5 — leave both nodes running and run the checker
Then stop both nodes cleanly.
