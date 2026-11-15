# Stage 04 Worksheet 2: Write the Kisumu POS test

**Output:** `my-work/04-functional-test-framework/kisumu_pos_rbf_test.py`, passing.
**Checker:** `./04-functional-test-framework/check_functional_test.sh`

You did this flow by hand in Stage 03. Now you make a machine do it forever, on two nodes.

## Step 1 — copy the skeleton
Copy [`kisumu_pos_rbf_test.py`](./kisumu_pos_rbf_test.py) into your `my-work` folder. Every
`TODO` is yours. Delete each `raise NotImplementedError` when you finish that method.

## Step 2 — the spec your test must enforce
1. Node 0 (customer) sends a 200-sat, BIP125-signalling self-transfer; node 1 (merchant) sees it
   with `bip125-replaceable` true and base fee exactly 200 sat.
2. A 250-sat replacement fails with RPC error **-26** and the rule-4 message fragment.
3. A 5,000-sat replacement evicts the original from **both** mempools.
4. Node 1 sends a 20,000-sat child of the replacement; node 0 reports `ancestorcount` 2,
   `fees.ancestor` 0.00025 BTC and `depends` = [replacement txid].
5. One mined block contains the replacement at index 1 and the child at index 2.

<details><summary>Hint 1 (concept)</summary>

`MiniWallet.create_self_transfer` returns a dict; `["hex"]` goes to `sendrawtransaction` and
`["new_utxo"]` is what a child spends. Reusing the **same** `utxo_to_spend` for three creations is
what makes them conflict.
</details>
<details><summary>Hint 2 (where)</summary>

`MAX_BIP125_RBF_SEQUENCE` is in `test_framework/messages.py`. `assert_raises_rpc_error` takes
`(code, message, function, *args)`; the message is a substring match.
</details>

## Step 3 — run it
Run your file directly with `--configfile`. When it passes, run it 5 times in a row. Any
failure → it is flaky → find the missing sync.

## Step 4 — the master question
In a comment in your test, write which bump would fail rule 4 on master (0.1 sat/vB incremental
feerate) for this tx's vsize. Show your arithmetic.
