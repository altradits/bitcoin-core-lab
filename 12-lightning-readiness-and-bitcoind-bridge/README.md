# Stage 12: Connect Lightning to your node

You confirm the six layer 1 skills Lightning needs, simulate channel
state updates and a justice penalty in Go, and inspect local Polar
networks that run LND, Core Lightning, and Eclair against a Polar
`bitcoind`. The optional hands on part opens a real channel on Polar.

## Goal

After this stage you can explain how `lnd` uses `bitcoind` (RPC plus
ZMQ), run the channel simulator, and open and close a channel on a
local Polar network.

## Why it matters

Lightning does not replace Bitcoin. Funding, commitment, HTLC, and
justice transactions are all standard layer 1 transactions using the
multisig, SegWit, timelock, hashlock, and fee bump skills from Stages
01 to 06. LND is a client of your node: it scans blocks, estimates
fees, and broadcasts through RPC, and it learns about new blocks over
ZMQ. Polar packages that whole stack into Docker containers so you can
practice with real Lightning software on regtest.

## Prerequisites

* Stages 01 to 06 (the six skills this stage builds on).
* Go 1.22 or later.
* For the optional part: Docker Desktop and Polar
  (https://lightningpolar.com) with one network created. The lab pins
  LND v0.20.0-beta, the version in the checked Polar networks.

## Setup

```bash
go -C ./12-lightning-readiness-and-bitcoind-bridge test ./...
```

Expected output:

```text
ok  	github.com/altradits/bitcoin-core-lab/12-lightning-readiness-and-bitcoind-bridge	0.805s
```

## Steps

### Step 1: Run the unit tests verbosely

```bash
go -C ./12-lightning-readiness-and-bitcoind-bridge test -v ./...
```

Expected output (the Polar presence test skips without `~/.polar`):

```text
--- PASS: TestRequiredBitcoinSkillsForLightningCompleteness (0.00s)
--- PASS: TestChannelBalanceConservationAndRevocationPenalty (0.00s)
--- PASS: TestInspectLocalPolarNetworksIfPresent (0.00s)
--- PASS: TestInspectLocalPolarNetworksFixture (0.00s)
ok
```

The channel test pins three outcomes: revoked broadcast inside the
delay pays everything to the victim, honest broadcast inside the delay
locks the broadcaster side, and honest broadcast after the delay pays
both sides.

### Step 2: Run the readiness program

```bash
go -C ./12-lightning-readiness-and-bitcoind-bridge run .
```

Expected output (abridged; Polar section depends on your machine):

```text
[1] THE 6 BITCOIN CORE SKILLS YOU MUST HAVE BEFORE LIGHTNING:
  1. UTXO Conservation & 2-of-2 Multisig (P2WSH / MuSig2)               [Stages 01 & 02]
  ...

[2] SIMULATING A LIGHTNING CHANNEL ON TOP OF BITCOIN CORE:
  • Channel Opened (State #0, 1 on-chain tx)  : Alice = 1000000 sats | Bob = 0 sats
  • Off-Chain Payment #1 (State #1, 0 L1 txs) : Alice = 750000 sats | Bob = 250000 sats (State #0 Revoked!)
  • Off-Chain Payment #2 (State #2, 0 L1 txs) : Alice = 600000 sats | Bob = 400000 sats (State #1 Revoked!)
  • Cheat Attempt on bitcoind (State #0)      : JUSTICE_PENALTY_APPLIED: ... (Bob gets 1000000 sats, revKey=...)
  • Honest Settlement on bitcoind (State #2)  : FORCE_CLOSE_MATURED: ... (Alice=600000, Bob=400000)

[3] POLAR AND DOCKER LIGHTNING NETWORKS IN ~/.polar:
  • Polar Network #1: "Addis Ababa Bootcamp" (/Users/mac/.polar/networks/1)
    - Bitcoin L1 Backend : backend1 (bitcoind v30.0)
    - Lightning L2 Nodes : alice (LND v0.20.0-beta | REST:8081 gRPC:10001), ...

[4] LOCAL BITCOIND REACHABLE (CURRENT REGTEST HEIGHT: #995)
    An LND node uses this RPC plus ZMQ block events to track channels.
```

Section 2 is the whole Lightning trust model in five lines: only open
and close touch layer 1, each payment revokes the old state, and a
cheat inside `to_self_delay` loses everything. If section 3 says
none found, install Polar and create a network, then rerun.

### Step 3: See how lnd talks to bitcoind

Open `~/.polar/networks/1/docker-compose.yml` and find the alice
service flags:

```text
--bitcoin.active --bitcoin.regtest --bitcoin.node=bitcoind
--bitcoind.rpchost=polar-n1-backend1 --bitcoind.rpcuser=polaruser --bitcoind.rpcpass=polarpass
--bitcoind.zmqpubrawblock=tcp://polar-n1-backend1:28334
--bitcoind.zmqpubrawtx=tcp://polar-n1-backend1:28335
```

LND needs five things from the node: block data (`getblock`), fee
estimates (`estimatesmartfee`), broadcast (`sendrawtransaction`,
`submitpackage` for anchors), wallet free chain scans, and live ZMQ
push of blocks and transactions. The ports section maps the Polar
backend RPC to host port 18446 so your host CLI can reach it:

```bash
bitcoin-cli -regtest -rpcport=18446 -rpcuser=polaruser -rpcpassword=polarpass getblockcount
```

Run this only while the Polar network is started.

### Step 4 (optional): Open a channel on Polar

Start network 1 in the Polar app (or
`docker compose -f ~/.polar/networks/1/docker-compose.yml up -d`),
then in a terminal:

```bash
./lab.sh polar
```

The command prints ready to run `lncli` lines for your machine,
including the TLS cert and macaroon paths. With them you can run
`getinfo`, `openchannel`, `sendpayment`, and `closechannel` against
alice. When done, stop everything to free RAM:

```bash
./lab.sh rest
```

## Checkpoint

```bash
./lab.sh check 12
```

Expected output:

```text
PASS: stage 12. unit tests passed; readiness program reached the node.
```

The check runs the unit tests plus the Step 2 program and requires
section 4 to report a height. Polar is not required for the check.
You can also rerun Steps 1 and 2 by hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| Section 3 says none found | Polar never created a network | Open Polar, create a network with one LND node, rerun |
| `[4] No local bitcoind on regtest` | Node down, or custom datadir | Start the node; export `BITCOIN_CLI` for custom setups |
| `Could not connect` on port 18446 | Polar network not started | Start it in Polar first |
| `macaroon not found` from lncli | Wrong network number in the path | Use the exact paths `./lab.sh polar` prints |
| Docker out of memory | Too many networks running | Run `./lab.sh rest`, keep one network up at a time |

## Going further

1. Change the simulator delay. Edit `toSelfDelayCSV` in the
   `EvaluateBroadcastedCommitment` calls and show a cheat that
   succeeds because the victim slept past the delay. Done when
   `BREACH_MISSED` prints.
2. Route a payment on Polar. Open alice to bob and bob to carol,
   then pay alice to carol through bob. Done when all three
   balances move correctly.
3. Force close on Polar and watch `bitcoind`. Close a channel with
   `--force`, find the commitment transaction on the Polar backend,
   and count the `to_self_delay` blocks. Done when the sweep
   confirms.

## Contribution task

LND and Core Lightning label beginner friendly issues. Pick one docs
or test only issue in `lightningnetwork/lnd` (for example a
`lncli` help text fix), reproduce the behavior on your Polar alice
node, and comment your reproduction steps on the issue. Never claim a
fix you did not run.

## Sources

* BOLT 2 (channel open and close) and BOLT 3 (transactions):
  funding, commitment, HTLC outputs.
* BOLT 5 (on chain handling): force closes and justice.
* LND docs (https://docs.lightning.engineering): `lnd` plus
  `bitcoind` backend configuration.
* Polar source networks on disk: `~/.polar/networks/*/docker-compose.yml`.
