# Stage README template

Every stage follows [CURRICULUM_CONVENTIONS.md](../CURRICULUM_CONVENTIONS.md): the student types
every command and writes every line of code that teaches a skill. Copy this file when you add a
stage, keep the sections in order, and delete the bracketed helper lines before you commit.

```
NN-stage-name/
  README.md        # this template
  exercises/       # worksheets (.md) and code skeletons with TODOs
  check_*.sh | *_test.go | test_*.py   # outcome checkers (PASS/FAIL with a reason, never the answer)
  solutions/       # reference answers and quiz answers (spoilers)
```

---

# Stage NN: <short plain title>

[One paragraph: what the student builds or verifies, and where it runs. Name regtest when the stage
touches a node.]

> **No shortcuts.** You type every command and write every line of code. Worksheets say what to
> achieve, not the command. Open `solutions/` only after a checker passes or after three honest
> attempts. Log what you typed in `my-work/NN-stage-name/journal.md`.

## Objectives

[Competency IDs from CURRICULUM.md, each with one line: "C-XXX-N: after this stage you can ...".]

## Prerequisites

[Earlier stages and tools, with versions. Link START_HERE.md for installs; do not repeat them.]

## Theory

[Short. Link one primary source per idea: a BIP, a BOLT, a whitepaper section, or an exact
Bitcoin Core file and function. Mark claims you could not check against source as **UNVERIFIED**.]

## Exercises

[One line per worksheet in `exercises/`, with what it produces and which checker verifies it.
Inside each worksheet: numbered goals, the RPC/file/function to use, and layered hints in
`<details>` blocks: Hint 1 (concept), Hint 2 (which RPC and its arguments). Never a final hint
with the full answer.]

| Worksheet | You produce | Checker |
| :--- | :--- | :--- |
| `exercises/01-....md` | <state, file or code> | `./check_....sh` |

## Checkpoint

```bash
./lab.sh check NN
```

[Say what a pass proves. Never paste output that gives away an answer.]

## Common errors and fixes (optional)

[Optional. Errors you hit while testing the stage on a fresh machine: exact text, cause, what to
look at. Point to the cause; do not hand over the fixed command.]

| Error | Cause | Where to look |
| :--- | :--- | :--- |
| `<exact error line>` | <why it happens> | <RPC help, file, or setting> |

## Self-check quiz

[5 to 10 questions answered from memory. Answers in `solutions/quiz_answers.md`.]

## Review lens

[How this stage's knowledge is used when reviewing a real bitcoin/bitcoin (or LND) pull request in
this area: the files and invariants to look at, and the questions to ask. Never a ready-to-post
review or ACK.]

## Sources

[Primary sources only. Link the exact file or section. Never invent a pull request number.]
