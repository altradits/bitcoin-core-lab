# SPOILER — Stage 08 quiz answers

1. P2PKH output = 8 (value) + 1 (len) + 25 (script) = 34 bytes; spending input assumed 32+4+1+107+4 = 148; total 182 × 3000/1000 = 546. P2WPKH output = 8+1+22 = 31; input with witness discount = 32+4+1+(107/4=26)+4 = 67; total 98 × 3 = 294.
2. The formula only looks at "is it a witness program", not the version; the comment in `GetDustThreshold` says the computation "was kept to not further reduce the dust level" (PR #22779).
3. 10000000 sats. 0.1*1e8 happens to come out exact in float64, but 0.29*1e8 = 28999999.9999999963 and truncates to 28999999 (checked with Go 1.26). Parsing with integers avoids this whole class of bug.
4. 40 bytes: 1 (OP_RETURN) + 1 (push len) + 40 = 42. 76 bytes: 1 + 2 (OP_PUSHDATA1 + len) + 76 = 79.
5. BIP21: `req-` marks a parameter the payer MUST understand (e.g. a condition on payment); ignoring it could pay under wrong terms. Optional params are safe to ignore.
6. No. bitcoind returns HTTP 500 (or 400/404) with a JSON `error` object for RPC-level errors; read and decode the body.
7. Wallet names may contain spaces, `/`, `#`, `?` — unescaped, they change the URL path or start a query/fragment and hit the wrong endpoint.
