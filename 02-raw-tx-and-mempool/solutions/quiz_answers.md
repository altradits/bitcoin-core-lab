# Stage 02 — quiz and worksheet answers (spoilers)

## Quiz
1. weight = 113 × 3 + 222 = 561 WU; vsize = ceil(561 / 4) = 141 vB.
2. Raw hex stores the hash's bytes in internal order; RPCs print them reversed (`uint256::GetHex`).
3. SHA256d of the serialization **without** marker, flag and witness. Signatures sit in the witness,
   so nobody can change the txid by re-encoding a signature; pre-signed children (e.g. Lightning
   commitment transactions spending a funding output) stay valid.
4. Nowhere. Fee = sum(input values) − sum(output values); input values come from the UTXO set.
5. 294 sat: output 31 B (8 value + 1 len + 22 script) + input-spend estimate 32+4+1+107/4+4 = 67 B,
   total 98 B × 3 sat/vB (`DUST_RELAY_TX_FEE = 3000` sat/kvB).
6. consensus, policy, consensus (a block with it at that height is `bad-txns-nonfinal`), policy,
   RPC guard.
7. Only its own input and the output with the same index; others may add inputs/outputs freely.
8. So a signer (e.g. a hardware wallet) knows how much it is spending without parsing whole
   previous transactions, and cannot be tricked into paying a huge fee; legacy signatures did not
   cover the amount.
9. Tip 1000: final when `nLockTime < tip + 1`.
10. `PreChecks` → (`ReplacementChecks` if conflicts) → `PolicyScriptChecks` →
    `ConsensusScriptChecks` → finalize/submit (in `AcceptSingleTransaction`).

## Worksheet 2 (the fixture transaction)
```
02000000 | 00 01 | 01
  a4fa50aa...e7de37 (reverse → 37dee79c7e2a98a4201cf589020aea74e120418b7132592dbca38ef2aa50faa4) | 00000000 | 00 | fdffffff
02
  00e1f50500000000 (100,000,000) | 16 | 0014 04f800386fa0ab00adfdee2bfbf4943125b7f1f9
  f0e90f2401000000 (4,899,990,000) | 16 | 0014 e2b9e1bdcf6e0c3a008e14413414622e648f744e
02 | 47 3044...62aa01 | 21 029611...180e
00000000
```
VERSION=2, MARKER_FLAG=0001, INPUT_COUNT=1, PREV_VOUT=0, SCRIPTSIG_LEN=0, SEQUENCE=4294967293,
OUTPUT_COUNT=2, WITNESS_ITEMS=2, SIG_LEN=71, SIGHASH_BYTE=01, PUBKEY_PREFIX=02, LOCKTIME=0,
TOTAL_SIZE=222, BASE_SIZE=113, WEIGHT=561, VSIZE=141, FEE_SATS=10000, FEERATE_SAT_VB=70.92,
SIGNALS_BIP125=yes,
TXID=997b9d94d0fcf69def1b022af1ec9e68a584d1cce3d7357c679e3c3aed4131f5,
WTXID=105eacfd3705c1f779a8c9686439a3db243c438f6c322320c8ec749477c54a80.

## Worksheet 4
`MAXFEE_ERROR_CODE=-25`, `MAXFEE_TMA_REASON=max-fee-exceeded`, `MAXFEE_LAYER=rpc`;
`DUST_REASON=dust` (details on v29: "dust, tx with dust output must be 0-fee"), `DUST_LAYER=policy`,
`DUST_THRESHOLD_P2WPKH_SATS=294`; `BELOWOUT_REASON=bad-txns-in-belowout`, `consensus`;
`NONFINAL_REASON=non-final`, `consensus`, `LOCKTIME_FIRST_OK_TIP = NONFINAL_LOCKTIME`;
`VERSION_REASON=version`, `policy` (`TX_MAX_STANDARD_VERSION = 3`).

Why the wallet signs the "outputs > inputs" tx: signing checks only that it can produce a valid
signature; value checks are consensus checks done at validation time. BIP143 does commit to the
input amount, so a signature made with a wrong amount would also be invalid.
