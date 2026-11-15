# Stage 11 quiz answers (spoilers)

1. Script (signature) verification for blocks that are ancestors of the `assumevalid` block. It never skips PoW, header validity, amounts, UTXO existence, double-spend checks or the supply cap, and if the assumed block is not in your best chain everything is verified.
2. 550 MiB (`MIN_DISK_SPACE_FOR_BLOCK_FILES`). The tx index points into block files that pruning deletes, so lookups would fail; Core refuses the combination at startup.
3. A backup that was never restored may be empty, corrupt, encrypted with a forgotten passphrase, or missing descriptors (e.g. imported later). Only a restore proves it.
4. It derives the same addresses, tracks incoming/outgoing payments and balances, and can create unsigned PSBTs. It cannot sign or reveal private keys.
5. ceil(10.5 + 3×68 + 2×31) = ceil(276.5) = 277 vB.
6. Signet blocks need a signature from the signet's challenge key (BIP325), so coins cannot be mined freely and the network is controlled; nobody pays for them, which lets you test real P2P behaviour safely and repeatably.
7. `initialblockdownload` becomes `false`, `blocks == headers`, and `verificationprogress` is close to 1.
