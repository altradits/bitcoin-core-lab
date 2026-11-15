# Stage 08: Builder Starter Kit (Go + bitcoind JSON-RPC, standard library only)

> **No shortcuts.** You write the money, dust, OP_RETURN, BIP21 and JSON-RPC code in
> `kit.go`. The HTTP shell in `cmd/kit` is only wiring. Reference answers are in
> [`solutions/`](./solutions/). Open them only after `./lab.sh check 08` passes or after 3 honest attempts.

Source checked: `bitcoin/bitcoin` 29.x `f490f5562d` and `master` `e75b76b12c`. Differences are called out.

## Objectives

| ID | You can... |
| :-- | :-- |
| **C-TX-2** | Drive bitcoind only through JSON-RPC from your own client: cookie auth, wallet endpoints, error objects. |
| **C-MEMPOOL-1** | Compute the dust threshold exactly like `GetDustThreshold`, and explain the OP_RETURN standardness limit and how it changed between 29.x and master. |
| **C-TX-4** *(proposed new ID: "application integration — amounts, BIP21, RPC client")* | Handle amounts in integer satoshis, and build and parse BIP21 URIs safely. |

## Prerequisites
Stage 07 (wallets `w07_watch` / `w07_signer` exist on your regtest node). Read `bip-0021.mediawiki` offline and [`doc/JSON-RPC-interface.md`](https://github.com/bitcoin/bitcoin/blob/master/doc/JSON-RPC-interface.md).

## Theory
1. **Money is an integer.** `CAmount` is `int64_t` satoshis ([`src/consensus/amount.h`](https://github.com/bitcoin/bitcoin/blob/master/src/consensus/amount.h)). RPC prints amounts as fixed 8-decimal numbers, and `AmountFromValue` ([`src/rpc/util.cpp`](https://github.com/bitcoin/bitcoin/blob/master/src/rpc/util.cpp)) parses them with `ParseFixedPoint`. That function avoids floating point, because `0.1` cannot be represented exactly in binary.
2. **Dust.** An output is dust if spending it would cost more than it is worth at `-dustrelayfee` (`DUST_RELAY_TX_FEE = 3000` sat/kvB, [`src/policy/policy.h`](https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.h)). Read `GetDustThreshold` in [`src/policy/policy.cpp`](https://github.com/bitcoin/bitcoin/blob/master/src/policy/policy.cpp). Its comment derives 546 sat (P2PKH) and 294 sat (P2WPKH). Note the 75% witness discount applied to the 107-byte assumed signature+pubkey. Also note that taproot outputs use the *same* formula as P2WSH (330 sat), with the comment pointing to PR #22779.
3. **OP_RETURN.** `OP_RETURN <data>` outputs are provably unspendable (`CScript::IsUnspendable`), so their dust threshold is 0. How much data is *standard* is policy: on 29.x `MAX_OP_RETURN_RELAY = 83` bytes of script. On master it is `MAX_STANDARD_TX_WEIGHT / WITNESS_SCALE_FACTOR`. Verify both yourself with `git -C ~/bitcoin grep -n MAX_OP_RETURN_RELAY <branch> -- src/policy/policy.h`. Read the PR discussion behind that change before forming an opinion. A reviewer separates "what the code does" from "what I think policy should be".
4. **BIP21.** `bitcoin:<address>?amount=<BTC>&label=…&message=…`. Parameters are percent-encoded per RFC 3986. Unknown parameters are ignored, but an unknown `req-` parameter makes the whole URI invalid.
5. **JSON-RPC.** Auth uses the `.cookie` file (`__cookie__:<random>`) or `rpcauth`. Wallet calls go to `/wallet/<name>`. bitcoind returns **HTTP 401 with an empty body** on bad auth. For some RPC errors it returns 404/500 **with** a JSON error body (see `JSONErrorReply` in [`src/httprpc.cpp`](https://github.com/bitcoin/bitcoin/blob/master/src/httprpc.cpp)), so a client must read the body even when the status is not 200.

## Exercises
```
./lab.sh blank 08                 # copies exercises/kit.go to ./kit.go (your old file is backed up)
./lab.sh check 08                 # go test ./... — fails until you implement everything
go test -run TestDust ./...       # one area at a time: TestAmounts, TestDust, TestOPReturn, TestBIP21, TestRPC
```
<details><summary>Hint 1 (concept)</summary>For <code>ParseBTC</code>, split on "." and pad the fraction to 8 digits. For <code>DustThreshold</code>, first compute the serialized size of the output, then add the size of the input that would spend it.</details>
<details><summary>Hint 2 (where)</summary><code>GetDustThreshold</code> (policy.cpp) and <code>CFeeRate::GetFee</code> (src/policy/feerate.cpp, which rounds up). For the RPC client, <code>net/http/httptest</code> in the tests shows you exactly what the server sees.</details>

**Live run (after the tests pass).** Start your own regtest node, then:
```
go run ./cmd/kit -check
go run ./cmd/kit -wallet w07_watch
```
In another terminal, write your own `curl` calls against `POST /api/invoice` (body `{"amount_btc":"0.0005","label":"…"}`) and `POST /api/opreturn` (body `{"data_hex":"…"}`). Save them in `my-work/08-builder-starter-kit/journal.md`.

### Builder challenges (no tests given: write the test first, then the code)
- **A. Taproot invoices:** accept `"address_type":"bech32m"` and pass it to `getnewaddress`. Add a test in `kit_test.go` that the dust threshold for `5120<32 bytes>` is 330 at 3000 sat/kvB.
- **B. Fee bump endpoint:** `POST /api/bumpfee {txid}` calls `bumpfee` on the watch-only wallet. What error does Core give, and why? Find the answer in `src/wallet/rpc/spend.cpp`, then use `psbtbumpfee` instead and finish the bump with the Stage 07 PSBT flow.
- **C. OP_RETURN verifier:** `GET /api/verify?txid=…&data_hex=…` uses `getrawtransaction <txid> true` and compares the `nulldata` output's script hex with your `BuildOPReturnScript`.

## Self-check quiz (answers: [`solutions/quiz_answers.md`](./solutions/quiz_answers.md))

After marking your answers, record the score in `my-work/quiz-scores.env` as `QUIZ_08=<right>/<total>` (Gates 1 and 2 ask for 80%; `./lab.sh progress` reads it).
1. Why is P2WPKH dust 294 sat while P2PKH is 546 sat? Show the byte arithmetic.
2. Why does a P2TR output have the same dust threshold as P2WSH even though spending it is cheaper?
3. What does `ParseBTC("0.1")` return, and what goes wrong if you compute `0.1 * 1e8` in float64 and truncate?
4. A 40-byte payload: what is the full OP_RETURN script length? A 76-byte payload?
5. Why must a BIP21 parser reject `req-foo=1` but ignore `foo=1`?
6. Your client gets HTTP 500. Is the RPC call necessarily a transport failure?
7. Why path-escape the wallet name in `/wallet/<name>`?

## Review lens: reading a policy/RPC PR
- **Files:** `src/policy/policy.{h,cpp}`, `src/policy/feerate.cpp`, `src/httprpc.cpp`, `src/rpc/util.cpp`, `src/wallet/rpc/*.cpp`.
- **Tests:** `test/functional/mempool_dust.py`, `test/functional/mempool_datacarrier.py`, `test/functional/interface_rpc.py`, `src/test/amount_tests.cpp`, `src/test/transaction_tests.cpp` (search `IsDust`).
- **Questions:** Does the change alter what my node *relays* (policy) or what is *valid* (consensus)? Are default values documented in `-help` and release notes? Does an RPC change keep backward compatibility (deprecation flags)? Are amounts ever routed through `double`?

## Proof of work
A passing `./lab.sh check 08`, plus a short write-up in your own words: "How Core decides an output is dust", with the arithmetic for three script types.
