# Stage 03 quiz answers (spoilers)

1. v29: incremental 1 sat/vB → 400 + 1 × 210 = **610 sat**, and rule 6 also needs feerate > 2 sat/vB (610/210 = 2.9 ✓).
   master: incremental 0.1 sat/vB → 400 + ceil(0.1 × 210) = **421 sat**, and the feerate diagram must improve (it does: same position, more fee).
2. Feerate alone could fall in absolute terms: a smaller replacement can have a higher feerate but pay less total fee, so miners would earn less and the network would relay ever-smaller replacements for free. Rule 3 keeps miner revenue monotone; rule 4 makes every relay pay.
3. Yes. Since v28.0 full-RBF is the default (PR #30493), so signalling is not consulted. `bip125-replaceable` reports only the BIP125 signal (`nSequence <= 0xfffffffd` on an input or an ancestor), so it says `no`.
4. ceil(20 × (150 + 110)) − 150 = 5200 − 150 = **5050 sat**.
5. One extra descendant (≤ 10,000 vB, `EXTRA_DESCENDANT_TX_SIZE_LIMIT`) is allowed beyond the descendant limit if it has only one unconfirmed ancestor. Lightning needed it: either party must be able to CPFP its anchor even if the counterparty filled the descendant limit (pinning). TRUC and cluster mempool replace it on master.
6. It is pre-signed by both parties; changing the fee needs a new signature from the counterparty, who may be offline or hostile. Hence anchors + CPFP, and TRUC/package relay.
7. It stops a replacement from adding new low-feerate unconfirmed ancestors, which v0.12-era code could not price correctly (the replacement's "real" mining score would be lower than its own feerate). Cluster mempool evaluates the whole feerate diagram, so the rule became unnecessary.
8. `PaysForRBF` in `src/policy/rbf.cpp`.
