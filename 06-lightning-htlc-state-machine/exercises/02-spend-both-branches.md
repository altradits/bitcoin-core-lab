# Stage 06 Worksheet 2: Fund it and spend both branches with your own Python

**Output:** `my-work/06-lightning-htlc-state-machine/htlc_spend.py` and three txids on your node.
**Checker:** `./check_htlc_spends.sh`

Start from [`htlc_spend_skeleton.py`](./htlc_spend_skeleton.py). It imports the right pieces of
`test_framework` and leaves every line that teaches a skill as a TODO.

## Spec
1. **Fund:** one tx paying **two** outputs of 1 BTC each to your P2WSH address (vout 0 for the
   claim, vout 1 for the refund). Record `FUND_TXID`. Mine 1 block.
2. **Wrong preimage first:** build the claim with a wrong 32-byte preimage; `testmempoolaccept` →
   record the short reason as `WRONG_PREIMAGE_REASON` (only the part before ` (`).
3. **Claim:** spend vout 0 with the merchant signature and the real preimage. Record `CLAIM_TXID`.
4. **Early refund:** spend vout 1 with `nSequence = CSV_DELAY` while the funding tx has fewer than
   `CSV_DELAY` confirmations; `testmempoolaccept` → `EARLY_REFUND_REASON`.
5. **Refund:** mine just enough blocks — compute how many on paper (`BLOCKS_TO_MINE`) — then
   broadcast the **same signed** refund tx. Record `REFUND_TXID` and mine 1 block.

<details><summary>Hint 1 (keys)</summary>

Simplest honest route: make the keys in Python with `ECKey()` and `set(<32 secret bytes>, True)`,
derive the pubkeys from them, and rebuild your Worksheet 1 script with **those** pubkeys. Update
`MERCHANT_PUBKEY`/`SENDER_PUBKEY`/`HTLC_SCRIPT_HEX` in your answers so both checkers agree.
</details>
<details><summary>Hint 2 (sighash)</summary>

For P2WSH the BIP143 `scriptCode` is the witness script itself, and the amount is the value of
the output being spent. `SegwitV0SignatureHash(script, tx, input_index, hashtype, amount_sats)`.
Append the sighash byte to the DER signature.
</details>
<details><summary>Hint 3 (blocks to mine)</summary>

A coin mined at height h gets 1 confirmation at height h. BIP68 needs `tip+1 - h >= delay` for
the next block. Count, do not guess.
</details>
