# Stage 04 Worksheet 3: Prove your test catches a bug

**Output:** a passing normal run and a **failing** mutated run.
**Checker:** `./04-functional-test-framework/check_functional_test.sh --mutation`

A test that never fails proves nothing. Reviewers ask: "if I revert the fix, does this test fail?"

The checker re-runs your test with the node option `-incrementalrelayfee=0` added to both nodes
(through an environment variable your test does not need to know about). With no incremental
feerate, rule 4 accepts the +50-sat replacement, so **a good test must fail** at step 2.

## Your task
1. Before running the checker, predict in your journal which assertion fails and with what output.
2. Run `check_functional_test.sh --mutation`. It passes only if your test fails under mutation.
3. Name one more mutation of Bitcoin Core (a one-line source change in `src/policy/rbf.cpp`)
   that your test would catch, and one it would **not** catch. Write both in your journal. You
   will do real mutations in Stage 09 and 17.

<details><summary>Hint</summary>

If your test still passes under mutation, it is not asserting the rejection — perhaps it catches
any exception, or it never sends the bad replacement at all.
</details>
