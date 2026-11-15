# Stage 15 quiz answers (spoilers)

1. Context-free checks can run as soon as a block arrives (even before the parent is known), are cacheable and cheap; contextual checks need the parent/chain state (height, time, difficulty, active deployments).
2. In `ConnectBlock`, through the block's `CCoinsViewCache`: `Consensus::CheckTxInputs` reads them, `UpdateCoins` spends them and adds the new outputs; undo data is collected at the same time.
3. For each block: the coins it spent (`CTxUndo` per tx, inside `CBlockUndo`). Used by `DisconnectBlock` to restore the UTXO set during a reorg.
4. It is resubmitted, then removed by `removeForReorg`'s filter because the coinbase it spends is no longer mature (depth < 100) on the new chain.
5. Most cumulative proof of work (`nChainWork`), among chains whose blocks are not known invalid and whose data we have; ties broken by which we saw first (`nSequenceId`).
6. Sets `BLOCK_FAILED_VALID` on that block (and, in 29.x, `BLOCK_FAILED_CHILD` on descendants), removes it and descendants from the candidate set, and disconnects back if it is in the active chain; then `ActivateBestChain` picks the best remaining chain.
7. Buried: activation at a hard-coded height, no signalling logic left in the code (simpler, can't be reorged into a different activation). BIP9: miners signal with version bits; the state machine (DEFINED → STARTED → LOCKED_IN → ACTIVE / FAILED) decides activation.
8. It validates the chain from genesis up to the snapshot height and compares the resulting UTXO-set hash with the snapshot's hard-coded hash. On mismatch the snapshot chainstate is marked invalid, the node stops using it and reports the error loudly.
9. It works in a temporary child `CCoinsViewCache`; changes are flushed to the parent only after the block fully validates. A failure discards the child.
10. Anything that can affect whether a block is accepted is consensus, including limits of databases and libraries you depend on. Changes must be reviewed for behavioural equivalence on *all* inputs, and upgrades must not accidentally tighten or loosen rules.
