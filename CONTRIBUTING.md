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

1. Copy [docs/STAGE_TEMPLATE.md](./docs/STAGE_TEMPLATE.md). Keep the
   10 sections in order.
2. Show every command with its real expected output, captured from a
   run on regtest (Bitcoin Core v29.0 unless the stage says
   otherwise). Never invent output.
3. End with a working `./lab.sh check NN`. If you add a stage, add
   its check in the same pull request.
4. Update [START_HERE.md](./START_HERE.md) (stage map) and the stage
   table in [README.md](./README.md).
5. Keep one pull request to one stage or one theme, small enough to
   review in 30 minutes.

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
- [ ] Stage READMEs follow the template; commands and outputs are real.
- [ ] CI is green.

## Code of conduct

Be kind and stay technical. Details in
[CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).
