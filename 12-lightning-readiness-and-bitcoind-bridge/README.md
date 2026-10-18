# Stage 12: The Bitcoin-to-Lightning Readiness Gate, `lnd` <-> `bitcoind` Bridge & Polar/Docker Simulation Lab

> *"Lightning is not a separate cryptocurrency and it is not magic. Every Lightning channel, off-chain balance update, HTLC payment, and penalty transaction is 100% a standard Bitcoin Core transaction. Once you master the 6 Layer-1 Bitcoin Core building blocks below, you use your installed Polar + Docker networks (`Addis Ababa Bootcamp` & `Bitrust Bootcamp 2026`) and `/Users/mac/bin/lncli` to simulate multi-node Lightning like a protocol engineer."*

---

## Part 1: Your 6-Point Readiness Checklist Before Venturing Into Lightning

Do **not** launch `lnd` or Polar until you can check off all **6 Bitcoin Core Layer-1 Prerequisites** below. Every single one of them is already built and verified in Stages 01–10 of this repository:

| # | Required Bitcoin Core Skill | Where You Master It | How Lightning Uses It | What Breaks in Lightning Without It |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **UTXO Conservation & 2-of-2 Multisig (`P2WSH` / `MuSig2`)** | [`01-node-foundations`](../01-node-foundations/) & [`02-raw-tx-and-mempool`](../02-raw-tx-and-mempool/) | **BOLT #3 Funding Transaction:** Opening a Lightning channel simply locks satoshis into a single 2-of-2 multisig UTXO on `bitcoind`. | Without 2-of-2 multisig, your channel partner could steal your funds unilaterally. |
| **2** | **SegWit Transaction Malleability Fix (`txid` vs `wtxid`, BIP141)** | [`02-raw-tx-and-mempool`](../02-raw-tx-and-mempool/) | **Pre-Signed Refund/Commitment Transactions:** Before Alice broadcasts the Funding Tx, Alice and Bob sign Commitment Txs spending that Funding Tx's `txid`. | Before SegWit (2017), anyone could tweak signature bytes in `scriptSig` to change the Funding `txid`, invalidating your Commitment Tx and locking your money forever! |
| **3** | **Unbroadcast Signed Transactions & Asymmetric Revocation** | [`02-raw-tx-and-mempool`](../02-raw-tx-and-mempool/) & [`07-psbt-descriptors-and-miniscript`](../07-psbt-descriptors-and-miniscript/) | **BOLT #3 Off-Chain State Updates:** Paying on Lightning means signing a *new* Bitcoin transaction off-chain and giving your peer the **Revocation Secret** for the old transaction. | Every payment would require a 10-minute on-chain block and an on-chain miner fee. |
| **4** | **Relative Timelocks (`nSequence` BIP68 & `OP_CHECKSEQUENCEVERIFY` BIP112)** | [`06-lightning-htlc-state-machine`](../06-lightning-htlc-state-machine/) | **LN-Penalty (`to_self_delay`):** Forces the broadcaster of a Commitment Tx to wait `N` blocks (e.g., 144 blocks) before spending their own output. | If Alice broadcasted an old state from last week where she had more sats, she could spend the money immediately before Bob could punish her! |
| **5** | **Hashlocks (`OP_SHA256`) + Absolute Timelocks (`OP_CLTV` BIP65)** | [`06-lightning-htlc-state-machine`](../06-lightning-htlc-state-machine/) & [`10-protocol-primitives-from-scratch`](../10-protocol-primitives-from-scratch/) | **BOLT #2/#3/#4 HTLC Multi-Hop Routing:** Allows Alice to pay Carol through Bob (`SHA256(Preimage) == PaymentHash`) without trusting Bob. | Routing nodes in the middle of a payment path could take your sats and disappear. |
| **6** | **Mempool Fee Bumping (`BIP125 RBF`, `CPFP`, & `BIP431 TRUC v3 Package Relay`)** | [`03-rbf-and-cpfp`](../03-rbf-and-cpfp/) & [`05-truc-package-relay-review`](../05-truc-package-relay-review/) | **Anchor Outputs & Ephemeral Anchors (`submitpackage`):** Bumps the fee of a pre-signed Commitment Tx at broadcast time when the mempool is congested. | If on-chain fees spike to `100 sat/vB`, a force-close or HTLC claim tx gets stuck in the mempool past its block deadline and funds are stolen! |

---

## Part 2: How Lightning Actually Works (In 4 Simple Steps)

Run `./lab.sh practice 12` to see [`lightning_readiness.go`](file:///Users/mac/bitcoin-core-lab/12-lightning-readiness-and-bitcoind-bridge/lightning_readiness.go) execute this exact state machine:

```
+-----------------------------------------------------------------------------+
| LAYER 1 (BITCOIN CORE - bitcoind):                                          |
|   [Funding Tx (Broadcast on L1)] ---> Creates 1_000_000 sat 2-of-2 UTXO     |
|                                              |                              |
| - - - - - - - - - - - - - - - - - - - - - - -|- - - - - - - - - - - - - - - |
| LAYER 2 (LIGHTNING - lnd, OFF-CHAIN):        v                              |
|   State #0 (Revoked): Alice = 1,000,000 | Bob =         0 (Not broadcast!)  |
|   State #1 (Revoked): Alice =   750,000 | Bob =   250,000 (Not broadcast!)  |
|   State #2 (Latest) : Alice =   600,000 | Bob =   400,000 (Held in RAM/DB)  |
| - - - - - - - - - - - - - - - - - - - - - - -|- - - - - - - - - - - - - - - |
| LAYER 1 SETTLEMENT (BITCOIN CORE - bitcoind):v                              |
|   [Closing Tx (Broadcast on L1)] ---> Alice: 600k sats | Bob: 400k sats     |
+-----------------------------------------------------------------------------+
```

---

## Part 3: How `lnd` Talks to `bitcoind` (The 5 Exact Bridge Calls)

A Lightning node (`lnd`) **cannot function without a Bitcoin node (`bitcoind`)**. Look at lines 44–48 of your own Polar Docker file [`/Users/mac/.polar/networks/1/docker-compose.yml`](file:///Users/mac/.polar/networks/1/docker-compose.yml#L44-L48):
```yaml
--bitcoin.active --bitcoin.regtest --bitcoin.node=bitcoind
--bitcoind.rpchost=polar-n1-backend1 --bitcoind.rpcuser=polaruser --bitcoind.rpcpass=polarpass
--bitcoind.zmqpubrawblock=tcp://polar-n1-backend1:28334
--bitcoind.zmqpubrawtx=tcp://polar-n1-backend1:28335
```
Under the hood, `lnd` uses `bitcoind` for 5 things:
1. **`getblockchaininfo` / `getblock`:** Scans every block mined on `bitcoind` to confirm channel opens (Funding UTXOs) and detect if a cheating peer broadcasts a revoked Commitment Transaction.
2. **`estimatesmartfee`:** Queries `bitcoind` for current `sat/vB` feerates.
3. **`sendrawtransaction`:** Broadcasts channel opens, cooperative closes, force-closes, and justice transactions to the Bitcoin P2P network.
4. **`submitpackage` (Stage 05):** Submits 0-fee Commitment Transactions + Anchor CPFP children atomically into `bitcoind`'s mempool.
5. **ZMQ (`28334` / `28335`):** Pushes raw blocks and transactions from `bitcoind` to `lnd` in real time.

---

## Part 4: How to Use Your Installed Polar & Docker Setup (`~/.polar`) Like a Protocol Engineer

We inspected your Mac and found **Polar (`/Applications/Polar.app`)**, **Docker (`/Applications/Docker.app`)**, and **two pre-configured multi-node Lightning networks** in `/Users/mac/.polar/networks/`:

1. **Polar Network #1 (`Addis Ababa Bootcamp`, [`/Users/mac/.polar/networks/1/docker-compose.yml`](file:///Users/mac/.polar/networks/1/docker-compose.yml)):**
   - **Bitcoin Core L1 Node:** `polar-n1-backend1` (`bitcoind v30.0`, Host RPC port `18446`, ZMQ `28334`/`28335`)
   - **LND Node 1 (`alice`):** `polar-n1-alice` (`LND v0.20.0-beta`, REST `8081`, gRPC `10001`, P2P `9735`)
   - **Core Lightning Node (`bob`):** `polar-n1-bob` (`CLN v25.12`, REST `8182`, gRPC `11002`, P2P `9836`)
   - **Eclair Node (`carol`):** `polar-n1-carol` (`Eclair v0.13.1`, REST `8283`, P2P `9937`)
   - **LND Node 2 (`dave`):** `polar-n1-dave` (`LND v0.20.0-beta`, REST `8084`, gRPC `10004`, P2P `9738`)
2. **Polar Network #2 (`Bitrust Bootcamp 2026`, `/Users/mac/.polar/networks/2/docker-compose.yml`):**
   - `backend1` (`bitcoind v30.0`), `alice` (`LND`), `bob` (`c-lightning`), `carol` (`eclair`).

### ⚠️ Golden Rule for Your 8 GB RAM Apple M1 MacBook Air
Running Docker Desktop + 5 containers (`bitcoind` + `2x LND` + `CLN` + `Eclair`) uses **`~3.5 GB` of RAM**.
- **When working on Stages 00–11 (Bitcoin Core C++ & Regtest):** Keep Docker Desktop and Polar **quit/stopped** so 100% of your 8 GB RAM stays free for your native `/Users/mac/bitcoin/build/bin/bitcoind` and C++ compiler.
- **When practicing Stage 12 (Multi-Node LND in Polar):** Open `Docker.app` and `Polar.app` (or start Network #1 via `docker compose`), run your Lightning channel drills below, and stop Polar/Docker when finished!

---

## Part 5: Step-by-Step Terminal Drills With Polar & `lncli` (No GUI Clicking!)

Anyone can click buttons in the Polar GUI. To become a Btrust-grade open-source developer, you must know how to drive Polar's Docker containers **directly from your terminal and Go/Python code** using `lncli`, `tls.cert`, and `admin.macaroon`.

Run `./lab.sh polar` anytime to print these exact commands customized for your Mac:

### Drill A: Talk to Polar's `alice` LND Node Using Your Native `/Users/mac/bin/lncli`
Every LND node requires two files to authenticate an API/CLI caller:
1. **`tls.cert`** (encrypts the connection)
2. **`admin.macaroon`** (cryptographic bearer token proving admin permission)

When Polar Network #1 is running, run this in your Mac terminal:
```bash
# Option 1: Using your native /Users/mac/bin/lncli on macOS talking to localhost:10001 (alice)
/Users/mac/bin/lncli \
  --network=regtest \
  --rpcserver=localhost:10001 \
  --tlscertpath=/Users/mac/.polar/networks/1/volumes/lnd/alice/tls.cert \
  --macaroonpath=/Users/mac/.polar/networks/1/volumes/lnd/alice/data/chain/bitcoin/regtest/admin.macaroon \
  getinfo

# Option 2: Executing lncli directly inside the polar-n1-alice Docker container
docker exec polar-n1-alice lncli --network=regtest getinfo
```

### Drill B: Talk Directly to Polar's Layer-1 `bitcoind` (`polar-n1-backend1`)
Notice in [`docker-compose.yml`](file:///Users/mac/.polar/networks/1/docker-compose.yml#L27) that Polar maps `backend1`'s RPC port `18443` to **`18446`** on your Mac so it never conflicts with your native `bitcoind -regtest` on port `18443`!
```bash
/Users/mac/bitcoin/build/bin/bitcoin-cli -regtest \
  -rpcport=18446 -rpcuser=polaruser -rpcpassword=polarpass \
  getblockchaininfo
```

### Drill C: Full Channel Lifecycle via CLI (`alice` <-> `dave` on Polar Network #1)
Once Polar Network #1 is started, walk through all 6 steps of a real LND channel from your terminal:

```bash
# 1. Fund Alice's LND on-chain wallet from Polar's backend1 bitcoind
ALICE_ADDR=$(docker exec polar-n1-alice lncli --network=regtest newaddress p2wkh | python3 -c "import sys,json; print(json.load(sys.stdin)['address'])")
/Users/mac/bitcoin/build/bin/bitcoin-cli -regtest -rpcport=18446 -rpcuser=polaruser -rpcpassword=polarpass generatetoaddress 6 "$ALICE_ADDR"

# 2. Get Dave's LND identity_pubkey and connect Alice -> Dave over P2P port 9735
DAVE_PUBKEY=$(docker exec polar-n1-dave lncli --network=regtest getinfo | python3 -c "import sys,json; print(json.load(sys.stdin)['identity_pubkey'])")
docker exec polar-n1-alice lncli --network=regtest connect "${DAVE_PUBKEY}@polar-n1-dave:9735"

# 3. Open a 1,000,000-satoshi Lightning Channel from Alice to Dave
docker exec polar-n1-alice lncli --network=regtest openchannel --node_key="$DAVE_PUBKEY" --local_amt=1000000

# 4. Mine 6 blocks on backend1 so the 2-of-2 Funding UTXO confirms on Layer 1!
/Users/mac/bitcoin/build/bin/bitcoin-cli -regtest -rpcport=18446 -rpcuser=polaruser -rpcpassword=polarpass generatetoaddress 6 "$ALICE_ADDR"
docker exec polar-n1-alice lncli --network=regtest listchannels

# 5. Create a BOLT #11 Invoice on Dave for 250,000 sats and pay it instantly from Alice!
PAY_REQ=$(docker exec polar-n1-dave lncli --network=regtest addinvoice --amt=250000 --memo="sovereign_lnd_drill" | python3 -c "import sys,json; print(json.load(sys.stdin)['payment_request'])")
docker exec polar-n1-alice lncli --network=regtest decodepayreq "$PAY_REQ"
docker exec polar-n1-alice lncli --network=regtest sendpayment --pay_req="$PAY_REQ" --force

# 6. Verify Alice now has ~750,000 sats local_balance and Dave has 250,000 sats remote_balance (with 0 on-chain txs!)
docker exec polar-n1-alice lncli --network=regtest channelbalance
docker exec polar-n1-dave lncli --network=regtest channelbalance
```

---

## Part 6: Your Guided Offline BOLT Study Order (`./lab.sh bolt <num>`)

All Lightning specifications (`BOLTs`) are stored offline in `/Users/mac/bitcoin-references/bolts/`. Read them alongside your Polar drills:
1. **`./lab.sh bolt 3` (BOLT #3: Bitcoin Transaction & Script Formats)** — Inspect the exact `to_local` (`OP_CSV`) and HTLC (`OP_SHA256` / `OP_CLTV`) scripts that `alice` and `dave` sign inside `listchannels`.
2. **`./lab.sh bolt 2` (BOLT #2: Peer Protocol for Channel Management)** — Matches `openchannel`, `sendpayment`, and `closechannel`.
3. **`./lab.sh bolt 11` (BOLT #11: Invoice Protocol)** — Matches `addinvoice` and `decodepayreq`.
4. **`./lab.sh bolt 4` (BOLT #4: Onion Routing Protocol)** — Try routing a multi-hop payment in Polar Network #1 from `alice` (LND) -> `bob` (Core Lightning) -> `carol` (Eclair) -> `dave` (LND)!
