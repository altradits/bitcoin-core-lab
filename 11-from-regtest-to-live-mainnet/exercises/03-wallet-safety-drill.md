# Stage 11 Worksheet 3: Wallet safety drill (regtest or signet)

**Output:** `my-work/11-from-regtest-to-live-mainnet/wallet_drill.env`.
**Checker:** `./11-from-regtest-to-live-mainnet/check_wallet_drill.sh` (asks your node)

Do it on **regtest** first (instant), then repeat on signet. Never practise with mainnet funds.
Read the help of: `createwallet`, `encryptwallet`, `walletpassphrase`, `walletlock`,
`backupwallet`, `restorewallet`, `listdescriptors`, `importdescriptors`, `getaddressinfo`, `getwalletinfo`.

1. Create a descriptor wallet `drill_hot` **with a passphrase** (choose one just for this drill).
   Record `HOT_WALLET=drill_hot`.
2. Receive coins to it (regtest: mine to it or send from `kisumu_miner`). Mine to confirm.
3. Back it up to a file under `my-work/`. Unload `drill_hot`. **Restore** the backup under a new
   name `drill_restored`. Record `RESTORED_WALLET=drill_restored`. Show both have the same balance
   and the same first receive address. Then load `drill_hot` again.
4. Export the **public** descriptors of `drill_hot` and import them into a new wallet
   `drill_watch` created with private keys disabled. Record `WATCH_WALLET=drill_watch`.
   Show `drill_watch` sees the same balance but cannot sign.
5. Lock `drill_hot` and try to send from it. Record the RPC error code as `LOCKED_SEND_ERROR_CODE`.

<details><summary>Hint 1 (watch-only import)</summary>

`listdescriptors` without `true` returns public descriptors with checksums, `timestamp`, `active`,
`internal` and `range`. `importdescriptors` takes the same fields back. Keep `internal` correct for
change descriptors, or the watch wallet will miss change outputs.
</details>
