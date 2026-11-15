# Stage 02 Worksheet 2: Decode a transaction byte by byte (no RPC until the end)

**Output:** answers in `my-work/02-raw-tx-and-mempool/answers.env` (section "Worksheet 2").
**Checker:** `./02-raw-tx-and-mempool/check_decode.sh` (offline: it does not need a node).

This is a real signed regtest transaction (1 input, 2 outputs, P2WPKH). The output it spends was
worth exactly **50.00000000 BTC**.

```
02000000000101a4fa50aaf28ea3bc2d5932718b4120e174ea0a0289f51c20a4982a7e9ce7de370000000000fdffffff0200e1f5050000000016001404f800386fa0ab00adfdee2bfbf4943125b7f1f9f0e90f2401000000160014e2b9e1bdcf6e0c3a008e14413414622e648f744e024730440220130f35e40a767e59cda01ec33abc4f81960337b791d8bc66f871044ff1f54237022021d36627c493e124fc560dd59740a515d854b349b97fc61f924b76b89d3d62aa0121029611910dcd6b4f48e0c3bb97b0a96f8954615ff6bb2d31d5256f7ad64697180e00000000
```

**Rules:** paper, pencil, and a terminal for counting/hex only (`echo -n ... | wc -c`, `printf '%d\n' 0x...`,
`xxd`, `shasum`). No `decoderawtransaction`, no Python `tx_from_hex`, until Part D.

## References
- Serialization: `SerializeTransaction` / `UnserializeTransaction` in `/Users/mac/bitcoin/src/primitives/transaction.h`
- CompactSize: `WriteCompactSize` in `/Users/mac/bitcoin/src/serialize.h`
- BIP141 (marker/flag, witness), BIP143 (segwit v0 sighash), BIP144 (wire serialization)
- Your offline books: `./lab.sh book 4`

---

## Part A — split the fields
Copy the hex into your journal and draw a vertical bar between every field. Then fill in:

| Key | Field |
|-----|-------|
| `VERSION` | version as a decimal number |
| `MARKER_FLAG` | the 2 bytes after the version (hex) |
| `INPUT_COUNT` | number of inputs |
| `PREV_TXID` | the txid of the spent output **as RPCs display it** |
| `PREV_VOUT` | output index spent |
| `SCRIPTSIG_LEN` | scriptSig length in bytes |
| `SEQUENCE` | nSequence as a decimal number |
| `OUTPUT_COUNT` | number of outputs |
| `OUT0_SATS`, `OUT1_SATS` | output values in satoshis |
| `OUT0_SPK` | output 0 scriptPubKey (hex) |
| `WITNESS_ITEMS` | number of witness stack items for input 0 |
| `SIG_LEN` | length in bytes of witness item 0 |
| `SIGHASH_BYTE` | last byte of witness item 0 (hex) |
| `PUBKEY_PREFIX` | first byte of witness item 1 (hex) |
| `LOCKTIME` | nLockTime as a decimal number |

<details><summary>Hint 1 (concept)</summary>

Integers are little-endian. Counts and lengths are CompactSize (one byte if < 0xfd). If the byte
after the version is `00` it cannot be an input count in a valid tx — that is the segwit marker.
Hashes are stored in "internal" byte order; RPCs print them reversed.
</details>

<details><summary>Hint 2 (field list)</summary>

version(4) · marker(1) flag(1) · vin count · [prev txid(32) · vout(4) · scriptSig len · scriptSig · sequence(4)] ·
vout count · [value(8) · spk len · spk] · witness: for each input, item count · [len · item] · locktime(4).
</details>

## Part B — sizes, weight, fee, feerate
| Key | Meaning |
|-----|---------|
| `TOTAL_SIZE` | bytes of the whole hex (with witness) |
| `BASE_SIZE` | bytes without marker, flag and witness data |
| `WEIGHT` | BIP141 weight units |
| `VSIZE` | virtual size (vB) |
| `FEE_SATS` | fee in satoshis |
| `FEERATE_SAT_VB` | fee / vsize, 2 decimals |
| `SIGNALS_BIP125` | `yes` or `no` |

<details><summary>Hint 1</summary>

weight = base × 3 + total (equivalently base × 4 + witness bytes). vsize = ceil(weight / 4).
Find `GetTransactionWeight` in `src/consensus/validation.h`.
</details>

<details><summary>Hint 2</summary>

BIP125 signalling: any input with nSequence < 0xfffffffe. Compare with `SignalsOptInRBF` in
`src/util/rbf.cpp`. (Since v28/v29 the mempool does not *require* signalling — Stage 03 — but the
flag still matters for the wallet's `bumpfee` on 29.x.)
</details>

## Part C — compute the txid and wtxid yourself
1. Build the **non-witness** serialization by deleting marker, flag and the witness section from
   the hex. Its length must equal `BASE_SIZE`.
2. Double-SHA256 it, then reverse the bytes. That is `TXID`.
3. Double-SHA256 the full hex, reverse → `WTXID`.

<details><summary>Hint 1</summary>

`echo -n <hex> | xxd -r -p | shasum -a 256` gives one SHA256 as hex. Feed that hex back through
`xxd -r -p | shasum -a 256` for the second round.
</details>

<details><summary>Hint 2</summary>

To reverse a hex string byte-wise: `echo <hex> | fold -w2 | tail -r | tr -d '\n'` (macOS `tail -r`).
</details>

## Part D — confirm with RPC, then explain
Only now run `decoderawtransaction` on the hex and compare every field. For each mismatch, write in
the journal which rule you misapplied. Then answer in the journal (own words):
1. Why does the `txid` not commit to the signature, and which attack does that stop?
2. The signature is DER: `30 <len> 02 <rlen> <r> 02 <slen> <s>` + sighash byte. Split item 0 and
   say why `SIG_LEN` is usually 71 or 72 bytes.
3. What does `SIGHASH_ALL` commit to? What would change with `SIGHASH_NONE`, `SIGHASH_SINGLE` and
   `ANYONECANPAY`? Use BIP143 and `SignatureHash` in `src/script/interpreter.cpp`.
4. Why does BIP143 put the **amount** of the spent output into the sighash, when legacy did not?
   (Think about hardware wallets and fee lies.)
