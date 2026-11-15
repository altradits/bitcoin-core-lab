# SPOILER — Stage 07 reference walkthrough

Open this only after `check_psbt_flow.sh` passes or after 3 honest attempts.
Your own journal is the deliverable. This is here so you can compare.

```bash
alias bcli='bitcoin-cli -regtest'
# 1
bcli createwallet w07_signer
bcli createwallet w07_watch true            # disable_private_keys=true
# 2  (private=false is the default; we want PUBLIC descriptors)
bcli -rpcwallet=w07_signer listdescriptors
#    copy the "desc" whose string starts wpkh( and has "internal": false
bcli getdescriptorinfo "<that desc>"        # "checksum" must match the #suffix
# 3  import receive + change (copy both wpkh descs, internal false/true)
bcli -rpcwallet=w07_watch importdescriptors '[
  {"desc":"<wpkh receive desc>","timestamp":"now","active":true,"internal":false},
  {"desc":"<wpkh change desc>","timestamp":"now","active":true,"internal":true}]'
# 4
ADDR=$(bcli -rpcwallet=w07_watch getnewaddress "" bech32)
bcli -rpcwallet=<your mining wallet> sendtoaddress "$ADDR" 0.5
bcli generatetoaddress 1 "$(bcli -rpcwallet=<your mining wallet> getnewaddress)"
# 5  Creator + Updater
DEST=$(bcli -rpcwallet=<another wallet> getnewaddress)
bcli -rpcwallet=w07_watch walletcreatefundedpsbt '[]' "[{\"$DEST\":0.25}]"
bcli decodepsbt "<psbt>" ; bcli analyzepsbt "<psbt>"     # next: signer
# 6  Signer (+ Finalizer, since finalize defaults to true)
bcli -rpcwallet=w07_signer walletprocesspsbt "<psbt>"    # complete: true
# 7  Combiner practice
bcli -rpcwallet=w07_signer walletprocesspsbt "<psbt>" false   # sign=false -> only updates
bcli combinepsbt '["<signed psbt>","<unsigned-but-updated psbt>"]'
# 8  Finalizer + Extractor
bcli finalizepsbt "<signed psbt>"                        # returns "hex", "complete": true
bcli sendrawtransaction "<hex>"
bcli generatetoaddress 1 "$(bcli -rpcwallet=<your mining wallet> getnewaddress)"
# 9  Miniscript
PK=$(bcli -rpcwallet=w07_signer getaddressinfo "$(bcli -rpcwallet=w07_signer getnewaddress)" | jq -r .pubkey)
bcli getdescriptorinfo "wsh(and_v(v:pk($PK),older(144)))"   # take "checksum"
bcli deriveaddresses "wsh(and_v(v:pk($PK),older(144)))#<checksum>"
```
