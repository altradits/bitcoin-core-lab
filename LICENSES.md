# Licences and attribution

This lab is original work under the MIT licence (see LICENSE).
It teaches from outside sources but copies almost none of them.
The rules below say what is copied, what is only linked, and why.

Checked: 2026-11-06.

## What the lab copies

* Short attributed quotes (one or two sentences) from the Bitcoin
  whitepaper in `offline-library/SATOSHI_WHITEPAPER.md`, used as
  study prompts next to original summaries.
* Short attributed quotes from Satoshi Nakamoto emails and forum
  posts in the workbooks (one paragraph at most each).
* Upstream merge commit messages and diffs in `pr-reviews/`, quoted
  for review study with the pull request number and author.
* Reviewer comments from `github.com/bitcoin/bitcoin` in
  `pr-reviews/merged-journeys/`, quoted with author and date.

## What the lab links instead of copying

| Source | Licence | Lab treatment |
| :--- | :--- | :--- |
| Bitcoin whitepaper | No explicit licence grant | Linked (https://bitcoin.org/bitcoin.pdf). Not reproduced. |
| _Mastering Bitcoin_ 3rd ed. (Antonopoulos, Harding) | CC BY-SA 4.0 | Referenced by local path only. Install or clone the book repo yourself. |
| _Mastering the Lightning Network_ (Antonopoulos, Osuntokun, Pickhardt) | CC BY-SA 4.0 | Referenced by local path only. |
| _Learning Bitcoin from the Command Line_ (various) | CC BY 4.0 | Referenced by local path only. |
| _Programming Bitcoin_ (Jimmy Song) | CC BY-NC-ND per its README; copyright page says all rights reserved | Referenced by local path only. Never copied: ND forbids derivatives. |
| BIPs and BOLTs | See their own repos | Cited by number. Read them from a local clone or the web. |

The `./lab.sh book` and `./lab.sh bip` commands read from your own
local copies (default `~/bitcoin-references`, override with
`BITCOIN_REFERENCES`). The lab ships none of these texts.

## How to add a source

1. Prefer a link and a citation over a copy.
2. If you must quote, keep it under one paragraph, attribute author
   and source, and confirm the licence allows it.
3. Update this file with the new row.
