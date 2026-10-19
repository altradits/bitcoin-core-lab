# Merged PR #36469 Review Journey: `refactor: deduplicate block validation state catcher`

- **Author:** `@enirox001`
- **Merged At:** `2026-10-14T08:07:56Z`
- **Final Merged Head Commit:** `c9cccf6d68c682e533876b4450f5ad7044a79f10`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-36469` (`git -C /Users/mac/bitcoin show pr-36469`)
- **Core Lesson for Reviewers:** How a clean C++ validation refactoring gets `Concept ACK` early, followed by concise one-line `ACK <commit>` approvals (`dedup is clean.`).

---

## 1. Original PR Description

```text
As mentioned in https://github.com/bitcoin/bitcoin/pull/34644#discussion_r2889315162 and https://github.com/bitcoin/bitcoin/pull/35675#discussion_r360301816, the validation state catchers were defined in the block template manager, `submitblock` rpc and mining test helpers, even though they do the same thing.

Moved this helper into `node/block_validation_state_catcher.h` and reuse it across all three callers. An optional validation state replaces the separate `found` flag where used, preserving each caller's registration and result handling

Replaces #36389 with the same commit on a dedicated branch.
```

## 2. Commit & Diff Stat (`git show --stat pr-36469`)

```text
commit c9cccf6d68c682e533876b4450f5ad7044a79f10
Author: Enoch Azariah <enirox001@gmail.com>
Date:   Wed Sep 30 12:29:11 2026 +0100

    refactor: deduplicate block validation state catcher
    
    Move the shared BlockValidationStateCatcher into a dedicated header
    and reuse it it in the block template manager, submitblock rpc, and
    mining test helpers
    
    Use an optional validation state instead of a separate 'found' flag,
    preserving each caller's existing result handling

 src/node/block_template_manager.cpp       | 36 ++++++------------------------
 src/node/block_validation_state_catcher.h | 37 +++++++++++++++++++++++++++++++
 src/rpc/mining.cpp                        | 25 ++++-----------------
 src/test/util/mining.cpp                  | 19 ++--------------
 4 files changed, 50 insertions(+), 67 deletions(-)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

_No inline diff comments on this PR (see general comments & reviews below)._

## 4. General Discussion & Maintainer Feedback Thread

### `@sedited` (2026-10-08T10:48:15Z)

Concept ACK

---

### `@w0xlt` (2026-10-08T15:26:22Z)

Concept ACK

---

### `@maflcko` (2026-10-13T09:30:27Z)

review ACK c9cccf6d68c682e533876b4450f5ad7044a79f1 🖋

<details><summary>Show signature</summary>

Signature:

```
untrusted comment: signature from minisign secret key on empty file; verify via: minisign -Vm "${path_to_any_empty_file}" -P RWTRmVTMeKV5noAMqVlsMugDDCyyTSbA3Re5AkUrhvLVln0tSaFWglOw -x "${path_to_this_whole_four_line_signature_blob}"
RUTRmVTMeKV5npGrKx1nqXCw5zeVHdtdYURB/KlyA/LMFgpNCs+SkW9a8N95d+U4AP1RJMi+krxU1A3Yux4bpwZNLvVBKy0wLgM=
trusted comment: review ACK c9cccf6d68c682e533876b4450f5ad7044a79f1 🖋
YXg33xQFEsbGv20Co4NpeVSPnWpOcqgCqsMdHbG2gR8/X8uOlrpulBHHty/HdgRpeaOXwWwxp3O2G+hpd7ZxAw==
```

</details>

---

## 5. Formal Reviews & Final `ACK`s

### `@Grace-Ujah` (`COMMENTED`)

Concept ACK 5852e3d35a42749d267f2783269a9568bf67e53d

---

### `@ismaelsadeeq` (`APPROVED`)

ACK c9cccf6d68c682e533876b4450f5ad7044a79f10

dedup is clean.

---

### `@sedited` (`APPROVED`)

ACK c9cccf6d68c682e533876b4450f5ad7044a79f10

---

### `@w0xlt` (`COMMENTED`)

ACK c9cccf6d68c682e533876b4450f5ad7044a79f10

---
