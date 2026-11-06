# Stage README template

Every stage README in this repo uses the same sections in the same
order. Copy this file when you add a stage. Delete these helper lines
(the ones in brackets) before you commit.

---

# Stage NN: <short plain title>

[One paragraph. Say what the student builds or verifies and where it
runs. Name regtest explicitly when the stage touches a node.]

## Goal

[One or two sentences. Start with "After this stage you can...".]

## Why it matters

[Two to five sentences. Link the stage to one primary source: a
whitepaper section, a BIP, a BOLT, or a Bitcoin Core subsystem. Say how
wallets, miners, or Lightning use this in practice.]

## Prerequisites

[Bullet list. Name the earlier stages and the tools this stage needs.
Link back to START_HERE.md for install steps. Do not repeat install
steps here.]

* Stage NN (what it provides).
* Tool and version, for example Bitcoin Core v29.0.

## Setup

[Numbered steps that leave the machine ready. Show every command and
one line that says what success looks like. Keep this short. If setup
takes more than five minutes, say so.]

```bash
<command>
```

Expected output:

```text
<exact or abbreviated output>
```

## Steps

[The main work. Number each step. Show every command with its expected
output. After each command, write one or two sentences that explain
what happened and why. A student working offline must be able to follow
this with no other page open.]

### Step 1: <what the student does>

```bash
<command>
```

Expected output:

```text
<output>
```

[Explanation.]

### Step 2: <next action>

[Same pattern.]

## Checkpoint

[How the student proves the stage works. Prefer one automated command,
for example `./lab.sh check NN`. Show the command and the exact output
of a pass. If there is no automated check yet, give two or three manual
commands with expected output.]

```bash
./lab.sh check NN
```

Expected output:

```text
<output of a passing check>
```

## Common errors and fixes

[Table or list. Include every error you hit while testing the stage on
a fresh machine. Give the exact error text, the cause, and the fix.]

| Error | Cause | Fix |
| :--- | :--- | :--- |
| `<exact error line>` | <why it happens> | <what to run> |

## Going further

[Two to four optional exercises, easiest first. Each one is one short
paragraph with a clear done condition.]

## Contribution task

[One real, small, upstream appropriate task that uses this stage. Good
examples: run one upstream functional test and report the result on a
pull request, review a small open pull request, fix one docs typo. Link
the exact test file or pull request. Never invent a pull request
number.]

## Sources

[Primary sources only, newest first within each group. Link the exact
file or section, not a whole repo.]

* Bitcoin Core: `src/...` file and function name.
* BIP or BOLT: number and title.
* Docs: `doc/...` path in bitcoin/bitcoin, or the LND docs page.
