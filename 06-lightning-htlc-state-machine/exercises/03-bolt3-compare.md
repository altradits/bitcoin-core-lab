# Stage 06 Worksheet 3: BOLT 3 — toy vs real

**Output:** answers in "Worksheet 3" and a comparison table in your journal.
**Checker:** `./check_bolt3.sh` (offline)

Open `~/bitcoin-references/bolts/03-transactions.md` (offline copy). Read sections
"Offered HTLC Outputs", "Received HTLC Outputs", "HTLC-Timeout and HTLC-Success Transactions" and
"`to_local` Output".

Answer from the text:
1. Which opcode hashes the preimage in the offered/received HTLC scripts? → `BOLT3_HASH_OPCODE`
2. How many bytes is the hash that the script compares against? → `BOLT3_HASH_LEN`
3. In the **received** HTLC output, which timelock opcode protects the offerer's timeout path?
   → `RECEIVED_TIMEOUT_OPCODE`
4. Which transaction field enforces `cltv_expiry` on an **HTLC-timeout** transaction?
   → `HTLC_TIMEOUT_TX_FIELD`
5. Which opcode delays the broadcaster's own `to_local` funds? → `TO_LOCAL_DELAY_OPCODE`
6. Which key lets the *other* party take all funds from a revoked commitment? (the name of the
   pubkey in the scripts) → `PENALTY_KEY_NAME`

In your journal, build a table with at least 5 rows: feature | toy HTLC | BOLT 3 | why BOLT 3 does it.
