# Merged PR #33630 Review Journey: `doc: correct topology requirements in submitpackage helptext`

- **Author:** `@glozow`
- **Merged At:** `2025-10-17T14:16:13Z`
- **Final Merged Head Commit:** `3d222825642bfb052ce40cbc1c69318a0d8835bf`
- **Local Git Branch in `/Users/mac/bitcoin`:** `pr-33630` (`git -C /Users/mac/bitcoin show pr-33630`)
- **Core Lesson for Reviewers:** How @janb84 and @instagibbs used GitHub ```suggestion blocks to refine ambiguous RPC helptext in `submitpackage`, which @glozow incorporated before merge.

---

## 1. Original PR Description

```text
This doc is outdated since #31385. Also made it explicit that a singleton is ok.

Can be backported to 30.x, but doesn't need to be backported earlier ("if any" covers #31096).
```

## 2. Commit & Diff Stat (`git show --stat pr-33630`)

```text
commit 3d222825642bfb052ce40cbc1c69318a0d8835bf
Author: glozow <gloriajzhao@gmail.com>
Date:   Tue Oct 14 15:59:15 2025 -0400

    [doc] correct topology requirements in submitpackage helptext

 src/rpc/mempool.cpp | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)
```

## 3. Inline Code Review Comments (Where Reviewers Improved the Code)

### `@janb84` on `src/rpc/mempool.cpp:939` (2025-10-15T11:18:20Z)

```diff
@@ -936,7 +936,7 @@ static RPCHelpMan submitpackage()
         ,
         {
             {"package", RPCArg::Type::ARR, RPCArg::Optional::NO, "An array of raw transactions.\n"
-                "The package must solely consist of a child transaction and all of its unconfirmed parents, if any. None of the parents may depend on each other.\n"
+                "The package must consist of either: exactly 1 transaction, or 1 transaction with its unconfirmed parents. None of the parents may depend on each other. Not all parents need to be present.\n"
```

> Text is not completely clear to me on the parents point. "or 1 transaction with its unconfirmed parents" but "Not all parents need to be present" so some of the unconfirmed parents ? all but not the confirmed parents ?  
> 
> Maybe NIT;
> ```suggestion
>                 "The package must consist of either: exactly 1 transaction, or 1 transaction with (some of) its unconfirmed parents. None of the parents may depend on each other. Not all parents need to be present.\n"
> ```

### `@instagibbs` on `src/rpc/mempool.cpp:939` (2025-10-17T12:57:27Z)

```diff
@@ -936,7 +936,7 @@ static RPCHelpMan submitpackage()
         ,
         {
             {"package", RPCArg::Type::ARR, RPCArg::Optional::NO, "An array of raw transactions.\n"
-                "The package must solely consist of a child transaction and all of its unconfirmed parents, if any. None of the parents may depend on each other.\n"
+                "The package must consist of either: exactly 1 transaction, or 1 transaction with its unconfirmed parents. None of the parents may depend on each other. Not all parents need to be present.\n"
```

> maybe?
> 
> ```suggestion
>                 "The package must consist of either: exactly 1 transaction, or 1 transaction with its unconfirmed parents. None of the parents may depend on each other. Not all in-mempool parents need to be present in the package.\n"
> ```

### `@glozow` on `src/rpc/mempool.cpp:939` (2025-10-17T13:29:54Z)

```diff
@@ -936,7 +936,7 @@ static RPCHelpMan submitpackage()
         ,
         {
             {"package", RPCArg::Type::ARR, RPCArg::Optional::NO, "An array of raw transactions.\n"
-                "The package must solely consist of a child transaction and all of its unconfirmed parents, if any. None of the parents may depend on each other.\n"
+                "The package must consist of either: exactly 1 transaction, or 1 transaction with its unconfirmed parents. None of the parents may depend on each other. Not all parents need to be present.\n"
```

> Incorporated this as (some, all, or none of)

### `@glozow` on `src/rpc/mempool.cpp:939` (2025-10-17T13:30:03Z)

```diff
@@ -936,7 +936,7 @@ static RPCHelpMan submitpackage()
         ,
         {
             {"package", RPCArg::Type::ARR, RPCArg::Optional::NO, "An array of raw transactions.\n"
-                "The package must solely consist of a child transaction and all of its unconfirmed parents, if any. None of the parents may depend on each other.\n"
+                "The package must consist of either: exactly 1 transaction, or 1 transaction with its unconfirmed parents. None of the parents may depend on each other. Not all parents need to be present.\n"
```

> Took this, but reworded a little bit.

## 4. General Discussion & Maintainer Feedback Thread

### `@kevkevinpal` (2025-10-14T21:31:16Z)

ACK [501b030](https://github.com/bitcoin/bitcoin/pull/33630/commits/501b030769ae538c5fc445729e82f0b08bcd288a)

Fairly straightforward change and makes it clearer what is accepted

---

### `@glozow` (2025-10-17T13:30:19Z)

Thanks for the reviews! Re-pushed to address comments.

---

### `@fanquake` (2025-10-17T14:24:37Z)

Backported to `30.x` in #33609.

---

## 5. Formal Reviews & Final `ACK`s

### `@janb84` (`COMMENTED`)

ACK 3d222825642bfb052ce40cbc1c69318a0d8835bf

PR updates helptext of submitpackage to be up 2 date with the reent changes in #31385 . New help text reflects changes in #31385 and is clear.

Thanks for incorporating my nit!

---

### `@instagibbs` (`APPROVED`)

ACK 3d222825642bfb052ce40cbc1c69318a0d8835bf

---
