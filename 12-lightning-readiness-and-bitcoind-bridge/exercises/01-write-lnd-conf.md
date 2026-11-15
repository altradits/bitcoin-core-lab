# Stage 12 Worksheet 1: Write `lnd.conf` and the matching `bitcoind` settings

**Output:** `my-work/12-lightning-readiness-and-bitcoind-bridge/lnd.conf` and `bitcoin-zmq.conf`.
**Checker:** `./12-lightning-readiness-and-bitcoind-bridge/check_lnd_conf.sh` (reads files only)

Sources: `lnd --help` (your binary), lnd's `sample-lnd.conf` (online, check the version tag),
Core's `doc/zmq.md`. Every setting needs a comment line saying why.

## Requirements for `lnd.conf`
1. Uses the regtest network and `bitcoind` as its backend (find the option group in `lnd --help`).
2. Talks to bitcoind's RPC on `127.0.0.1` at the regtest RPC port of **your** Stage 01 node.
3. Authenticates with bitcoind's **cookie file** (not a username/password).
4. Receives raw blocks and raw transactions over ZMQ on two **different** localhost TCP ports.
5. Has an alias of your choosing (lnd's `alias` option in the application section).

## Requirements for `bitcoin-zmq.conf` (the lines you would add to your regtest `bitcoin.conf`)
1. Publishes raw blocks and raw transactions on exactly the two ports lnd listens to.
2. Binds them to localhost.

<details><summary>Hint 1 (sections)</summary>

lnd's config file uses INI sections such as `[Application Options]`, `[Bitcoin]`, `[Bitcoind]`.
The command-line flag `--bitcoind.rpchost` becomes `bitcoind.rpchost=` inside `[Bitcoind]`.
</details>
<details><summary>Hint 2 (cookie)</summary>

Find the cookie option in `lnd --help` and where Core writes `.cookie` for regtest
(`<datadir>/regtest/.cookie`).
</details>
