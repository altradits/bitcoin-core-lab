# Stage 06 quiz answers (spoilers)

1. `OP_IF` 0x63, `OP_ELSE` 0x67, `OP_ENDIF` 0x68, `OP_SHA256` 0xa8, `OP_EQUALVERIFY` 0x88, `OP_CHECKSIG` 0xac, `OP_CHECKSEQUENCEVERIFY` 0xb2, `OP_DROP` 0x75.
2. 10 → `OP_10` = 0x5a (one byte). 144 → `0x02 0x90 0x00` (push 2 bytes; 144 = 0x90 has the sign bit set in one byte, so a 0x00 byte is needed for a positive CScriptNum).
3. BIP68 relative locks only apply to transactions with `version >= 2` (`CalculateSequenceLocks` ignores them otherwise), and `OP_CSV` fails if the tx version is < 2 (`CheckSequence`).
4. `non-BIP68-final` (policy check at the mempool tip via `CheckSequenceLocksAtTip`).
5. The wrong preimage fails **script** evaluation (`OP_EQUALVERIFY`) under mandatory (consensus) flags, so no block could ever contain it. The early refund is a valid script; the tx is just not final **yet**, so a later block can include it.
6. It is the argument for `OP_IF`, selecting the claim branch. `0x02` violates MINIMALIF (policy for segwit v0 → `non-mandatory-script-verify-flag`/`minimalif` rejection; consensus in tapscript).
7. RIPEMD160 output is 20 bytes vs 32: smaller scripts, lower fees, and the same 2^80+ collision resistance considered enough for this use.
8. Revocation: when moving to a new state, each party gives the other the secret for the old state's revocation key. Broadcasting an old commitment lets the counterparty sweep all funds via the revocation path during the `to_self_delay` CSV window.
