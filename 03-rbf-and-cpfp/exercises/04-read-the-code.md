# Stage 03 Worksheet 4: Read the code

**Output:** answers in "Worksheet 4". **Checker:** `./03-rbf-and-cpfp/check_code_reading.sh` (offline).

Work in `~/bitcoin`. Use `git grep`, not a web search. For master-only questions use
`git show master:<path>` or `git grep <pattern> master -- <path>`.

1. Which function in `src/policy/rbf.cpp` returns the long message you saw in Worksheet 1 Step 3?
   → `RULE4_FUNCTION`
2. Which `MemPoolAccept` member in `src/validation.cpp` calls it? → `RULE4_CALLER`
3. What is the v29 value of `MAX_REPLACEMENT_CANDIDATES`? → `MAX_REPLACEMENT_CANDIDATES`
4. In v29 `src/node/miner.cpp`, which `BlockAssembler` method selects transactions by ancestor
   feerate? → `V29_SELECTION_METHOD`. On master, which method replaced it? → `MASTER_SELECTION_METHOD`
5. On master, which function in `src/policy/rbf.cpp` implements the feerate-diagram rule?
   → `DIAGRAM_FUNCTION`
6. Value of `DEFAULT_INCREMENTAL_RELAY_FEE` (sat/kvB) in v29 and in master →
   `INCREMENTAL_V29`, `INCREMENTAL_MASTER`
7. In `src/wallet/feebumper.cpp`, which function builds the replacement for the `bumpfee` RPC?
   → `BUMPFEE_CREATE_FUNCTION` (hint: its name starts with `Create`).
8. Find the functional test that exercises rule 4 with the string `not enough additional fees`.
   → `RULE4_TEST_FILE` (file name only).

<details><summary>Hint (technique)</summary>

`git grep -n "not enough additional fees"` finds both the code and the tests. `git grep -n
"BlockAssembler::" -- src/node/miner.cpp` lists every method.
</details>
