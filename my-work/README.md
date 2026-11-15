# my-work/ — your command journal

This folder holds **your** work: the commands you typed, the code you wrote, and your notes.
The lab's no-shortcuts rule ([CURRICULUM_CONVENTIONS.md §1](../CURRICULUM_CONVENTIONS.md#1-the-no-shortcuts-rule))
depends on it.

## Layout
```
my-work/
  <stage-dir-name>/          # same name as the stage, e.g. 13-core-codebase-build-and-unit-tests
    journal.md               # private: all of my-work/ except this README is git-ignored
    notes.md, *.py, *.cpp…   # anything else you choose to keep
  reviews/<repo>-<PR>.md     # private review notes before you write a public comment
```

## What goes in `journal.md`
For each exercise:
1. **Goal:** the exercise ID and the outcome it asks for.
2. **Commands I typed**, in order, *including the ones that failed*, with one line on why each failed.
3. **What I checked:** which checker you ran and its PASS/FAIL line.
4. **From memory:** could you redo it without the journal? Note the date you retried.
5. **Questions left:** anything to ask at Review Club or BitDevs.

Do not paste output you have not read. Do not paste commands you did not type.

## Privacy
Everything in `my-work/` except this README is git-ignored, so you decide what becomes public. To publish
something (for example as evidence in
[BTRUST_READINESS_TRACKER.md](../BTRUST_READINESS_TRACKER.md)), copy it into a separate
file you have reviewed, check that it contains no secrets (wallet passphrases, RPC
passwords, xprvs, mainnet addresses you don't want linked to you), and commit that file.

## Integrity
Notes here are private study material. Anything you post publicly (reviews, PR text,
issue comments) is written fresh, in your own words, from your own testing.
Bitcoin Core's `doc/AI_POLICY.md` (on `master`) asks for exactly this.
