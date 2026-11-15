# Stage 12 quiz answers (spoilers)

1. The per-commitment secret of the old state, given to the counterparty (`revoke_and_ack`). With it, the counterparty can derive the revocation private key for that old commitment's outputs.
2. `to_local` belongs to the party who broadcast; if that state was revoked, the other side needs time to notice and use the revocation path. `to_remote` belongs to the non-broadcaster, who cannot cheat with the other party's commitment, so (in the original design) no delay is needed (anchor channels add a 1-block CSV for carve-out reasons).
3. After `to_self_delay` blocks the cheater can sweep `to_local`; the theft succeeds. That is why watchtowers exist.
4. `rawblock` and `rawtx`. Without them (and without `rpcpolling`), lnd would not learn about new blocks and mempool txs promptly: channel confirmations, breach detection and HTLC deadlines would be missed.
5. An HTLC must be claimed or timed out on-chain before `cltv_expiry`. If the claim tx cannot get into blocks in time (low fee, pinning, full mempool, package limits), the routing node can lose the HTLC amount. Mempool policy decides whether the tx propagates and is mined in time.
6. BOLT 11 (invoices); BOLT 3 (transaction and script formats).
7. A small output on the commitment tx that either party can spend to attach a CPFP child at broadcast time, so the commitment can be pre-signed with a low fee. It relies on CPFP, the CPFP carve-out (v2 anchors), and now package relay, TRUC and ephemeral dust (keyless anchors).
