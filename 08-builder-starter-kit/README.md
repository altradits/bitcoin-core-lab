# Stage 08: Build an app on top of bitcoind

You run a zero dependency Go HTTP server that talks to `bitcoind`
over JSON-RPC. It reports node state, creates BIP21 invoices from the
watch only wallet, and anchors document hashes on chain with
`OP_RETURN`.

## Goal

After this stage you can call any `bitcoind` RPC from Go, derive
watch only addresses, and build and broadcast transactions from an
app.

## Why it matters

Exchanges, merchants, and Lightning nodes are all apps sitting on this
same RPC interface. BIP21 standardizes payment URIs so wallets can pay
an invoice in one scan. `OP_RETURN` (a provably unspendable output)
timestamps data without bloating the UTXO set. This stage turns the
protocol pieces from Stages 02 and 07 into something a user can click.

## Prerequisites

* Stage 07 (the `sovereign_watch_only` wallet must exist with
  imported descriptors; the invoice endpoint derives from it).
* Go 1.22 or later. The server uses the Go 1.22 request pattern
  syntax (`GET /api/node`).

## Setup

```bash
go -C ./08-builder-starter-kit test ./...
```

Expected output:

```text
ok  	github.com/altradits/bitcoin-core-lab/08-builder-starter-kit	0.445s
```

If your node uses a custom datadir or RPC port, export the same
overrides as Stage 07 before the live steps:

```bash
export BITCOIND_RPC_URL="http://127.0.0.1:18443"
export BITCOIN_COOKIE="$HOME/Library/Application Support/Bitcoin/regtest/.cookie"
```

## Steps

### Step 1: Run the unit tests verbosely

```bash
go -C ./08-builder-starter-kit test -v ./...
```

Expected output:

```text
=== RUN   TestSatsToBTCAndBIP21
--- PASS: TestSatsToBTCAndBIP21 (0.00s)
=== RUN   TestBuildOPReturnScriptHex
--- PASS: TestBuildOPReturnScriptHex (0.00s)
=== RUN   TestRPCBaseURLDefaultAndOverride
--- PASS: TestRPCBaseURLDefaultAndOverride (0.00s)
=== RUN   TestLoadRegtestAuthExplicitCookie
--- PASS: TestLoadRegtestAuthExplicitCookie (0.00s)
PASS
```

The tests cover sat to BTC conversion with dust and MAX_MONEY
bounds, BIP21 URI building, and the `6a20` OP_RETURN script shape.

### Step 2: Run the demo against the live node

```bash
go -C ./08-builder-starter-kit run . --demo
```

Expected output (address differs):

```text
1. Computed OP_RETURN Commitment:
   SHA256: 57d9cdf179244a222253bc0883d3e64e8c48f97a332640f75bdbd7cb17e127f8
   Script: 6a2057d9cdf179244a222253bc0883d3e64e8c48f97a332640f75bdbd7cb17e127f8
2. Generated Watch-Only BIP21 Invoice (50,000 sats):
   bitcoin:bcrt1qq8quyc99k906unpplzcaq6u2ckw4ev4zf9e04z?amount=0.00050000&label=Builder+Demo
```

Line 1 hashes a document and shows the `OP_RETURN` script that would
commit to it (`6a` is OP_RETURN, `20` pushes 32 bytes). Line 2 derives
a fresh watch only address and formats a BIP21 URI for 50,000 sats.
If line 2 fails, rerun Stage 07 Step 2 first.

### Step 3: Start the server and call it

In one terminal:

```bash
go -C ./08-builder-starter-kit run .
```

Expected output:

```text
Bitcoin builder server listening on http://127.0.0.1:8080
```

In a second terminal:

```bash
curl -s http://127.0.0.1:8080/api/node | python3 -c "import sys,json; d=json.load(sys.stdin); print('height:', d['chain']['blocks'], 'mempool:', d['mempool']['size'])"
curl -s -X POST http://127.0.0.1:8080/api/invoice -d '{"amount_sats": 50000, "label": "probe invoice"}'
echo
curl -s -X POST http://127.0.0.1:8080/api/notarize -d '{"document_text": "probe doc 001"}'
```

Expected output (values differ):

```text
height: 995 mempool: 0
{"address":"bcrt1q0pl2lqvrp9s725r8uhelpt58atvxlc2cg9cxy9","amount_btc":"0.00050000","amount_sats":50000,"bip21_uri":"bitcoin:bcrt1q0pl2lqvrp9s725r8uhelpt58atvxlc2cg9cxy9?amount=0.00050000\u0026label=probe+invoice","watch_only":true}
{"document_sha256":"da730f019f474e06cd4314037ad6da8dfb282a763a6c5219e2996d0ebf719de4","op_return_hex":"6a20da730f019f474e06cd4314037ad6da8dfb282a763a6c5219e2996d0ebf719de4","txid":"87f15f24abf95165273832fec1ff1ae7dd4fb1ea21ef17d6df6f4c760268544e"}
```

Notes: Go escapes `&` as `\u0026` in JSON strings. Any JSON parser
decodes it back to `&`. The notarize call broadcasts a real regtest
transaction with a zero value `nulldata` output plus change. Stop the
server with Ctrl-C when done.

## Checkpoint

```bash
./lab.sh check 08
```

Expected output:

```text
PASS: stage 08. unit tests passed; invoice and notarize endpoints live.
```

The check runs the unit tests, starts the server on a test port,
calls all three endpoints, and stops the server. You can also rerun
Steps 1 to 3 by hand.

## Common errors and fixes

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `regtest .cookie or bitcoin.conf credentials not found` | Custom datadir | Export `BITCOIN_COOKIE` as in Setup |
| `getnewaddress failed` in the demo | Watch only wallet missing | Run Stage 07 Step 2, then retry |
| `bind: address already in use` on :8080 | Another server holds the port | Set `BUILDER_LISTEN_ADDR=127.0.0.1:18081` and retry |
| `Fee estimation failed` on notarize | Node without `-fallbackfee` | Restart the node with `-fallbackfee=0.00001` |
| Invoice below 546 sats rejected | Dust guard in `SatsToBTC` | Raise `amount_sats` to at least 546 |

## Going further

1. Add a Taproot invoice option. Accept `"address_type": "bech32m"`
   in `/api/invoice` and pass it to `getnewaddress`. Before
   changing the dust limit, read `GetDustThreshold` in
   `src/policy/policy.cpp`: Taproot keeps the P2WPKH dust
   computation, so 546 stays safe. Done when a `bcrt1p` invoice
   returns.
2. Add a fee bump endpoint. Call `bumpfee` on an unconfirmed wallet
   transaction and return both txids. Done when RBF replacement
   works through your endpoint.
3. Cap the notarize size. Reject `document_text` over 1 KB with a
   400 status and a clear message. Done when a large document is
   refused before any RPC call.

## Contribution task

Review a small open upstream RPC pull request the way a maintainer
would: read the diff, check out the branch, run the affected RPC by
hand on regtest, and leave a short Tested ACK or a question. A good
candidate is `bitcoin/bitcoin#36555` (`rpc: return error when
invalidateblock fails`), which is small and RPC focused. Never invent
results. Report only what you ran.

## Sources

* BIP21 (URI Scheme): the `bitcoin:` invoice format.
* `doc/REST-interface.md` and `doc/JSON-RPC-interface.md` in
  bitcoin/bitcoin: node interfaces.
* `src/policy/policy.cpp` (`GetDustThreshold`): dust math.
* `src/rpc/rawtransaction.cpp` (`walletcreatefundedpsbt` with a
  `data` output): OP_RETURN funding.
