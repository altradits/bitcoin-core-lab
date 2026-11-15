# Contributing to bitcoin-core-lab

Thanks for helping students learn Bitcoin Core and Lightning. Small,
careful changes beat big rewrites. Read this file before your first
pull request.

Contact: 5tan@altradits.com (or 0707172370 for urgent conduct issues).

## Ground rules

* Regtest and signet only. Never ask a student to use mainnet funds.
* Never print or paste secrets: no seeds, passphrases, private keys,
  or cookies in code, docs, issues, or chat logs.
* Plain tone: short sentences, no hype words, no emojis in headings,
  no em-dashes. Match the surrounding file.
* One line commit messages, lowercase scope, no body needed for small
  fixes. Example: `docs(stage-02): fix change output math`. No
  signing key required, no AI attribution lines.

## How to report a mistake in the lab

1. Open an issue with the lab bug form (or content correction form
   for wrong technical claims).
2. Name the exact file, step, command, and output. Paste the full
   error text and your `./lab.sh doctor` output.
3. Say what you expected. If you know the fix, say that too, but a
   clear report alone is welcome.

## How to add or change a stage

Every stage follows [CURRICULUM_CONVENTIONS.md](./CURRICULUM_CONVENTIONS.md) (the No-Shortcuts
Rule): the student types every command and writes every line of code that teaches a skill.

1. Copy [docs/STAGE_TEMPLATE.md](./docs/STAGE_TEMPLATE.md) and keep its sections in order.
2. Worksheets in `exercises/` say what to achieve and which RPC, file or function to use, with
   layered hints. They never show the finished command or code.
3. Checkers (`check_*.sh`, `*_test.go`, `test_*.py`) inspect the student's node, files or code and
   print PASS/FAIL with a reason. They never print the answer. Wire them into `./lab.sh check NN`.
4. Reference answers go in `solutions/`. Run the checker against them on regtest (Bitcoin Core
   v29.0 unless the stage says otherwise) and against an empty attempt; it must pass and fail.
   Never invent output. Mark anything you could not run as **UNVERIFIED**.
5. Go stages: keep a skeleton in `exercises/` and the reference in `solutions/`; `./lab.sh selftest`
   must show the skeleton failing and the solution passing.
6. Update [START_HERE.md](./START_HERE.md) (stage map), [CURRICULUM.md](./CURRICULUM.md) and the
   stage table in [README.md](./README.md).
7. Keep one pull request to one stage or one theme, small enough to review in 30 minutes.

## How to add a review or audit

* Verify the PR number, title, state, merge commit, and every quoted
  comment against github.com before submitting.
* Stamp open PR audits with the date checked. States change.
* Never pre-fill Tested ACK. Only sign what you built and ran.

## Pull request checklist

- [ ] `git status` shows only intended files.
- [ ] New or changed Go code passes `gofmt -l`, `go vet`, `go test`.
- [ ] New or changed scripts pass `bash -n` and run on regtest.
- [ ] New or changed Python passes `python3 -m py_compile`.
- [ ] Stage READMEs follow the template; worksheets show no finished answers; checkers pass on `solutions/` and fail on an empty attempt.
- [ ] `./lab.sh selftest` passes.
- [ ] CI is green.

## Code of conduct

Be kind and stay technical. Details in
[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).
