---
name: omarchy-plugin-publish
description: Prepare Omarchy Quattro plugins for marketplace submission, audit publishing and security-review blockers, fix authorized issues, and draft or submit exact-commit listings and revalidation requests. Use for Omarchy plugin publishing or HANCORE review feedback, not Codex plugin publishing or general desktop customization.
---

# Omarchy plugin publishing

Help an author reach a reviewable submission with minimal avoidable back-and-forth. Approval belongs to an authorized marketplace maintainer; never promise acceptance, a response time, or that an AI audit certifies safety.

## Establish the target

Identify the plugin repository/local path and any existing submission. Inspect before asking for information already available. Determine whether this is a new listing, a repair of an open submission, an update to a listed plugin, or verification of an existing snapshot. Do not open duplicates or change a permanent plugin ID to evade a review.

Read [requirements.md](references/requirements.md) for machine-enforced rules and validation commands. Refresh the linked live `SUBMISSION.md`, `SECURITY.md`, issue template, policy module, and relevant workflow before finalizing a submission. Record the marketplace source commit and research date. If offline, explicitly mark policy freshness and remote checks as unverified.

Read the entire relevant issue history, including current bot reports and maintainer comments. Bot comments are edited in place: their displayed contents may be newer than an earlier maintainer comment. Distinguish `github-actions[bot]` deterministic output from `HANCORE-linux` maintainer feedback. The latter's account type or prose does not establish whether AI assisted it.

## Audit and fix

Start with `scripts/readiness-check.sh /absolute/path/to/plugin` (add `--json` to consume the result). It is read-only and offline, and reports structural blockers, likely review questions, detected review capabilities and the commit you would submit. Treat it as a first sweep only: it reproduces the marketplace's structural rules and flags patterns for the five deterministic findings, but it is not the scanner, produces no bot evidence, and cannot see the data-flow problems below. Never report its output as a validation result.

Read [review-patterns.md](references/review-patterns.md). Research scope and sampled threads are recorded in [research-coverage.md](references/research-coverage.md). Inventory the whole shipped tree, then apply only the sections relevant to its actual behavior. Include QML, helpers, installers/removers, README and in-panel commands, dependencies/build tools, CI/release pipelines, companion apps, downloaded media, and optional/error/fallback paths. A lockfile or safe helper is insufficient if another exposed path bypasses it.

For each finding, report the file/line, data source, sensitive operation, concrete failure, fix, and source basis:

- **Official requirement:** documented contract or deterministic rule.
- **Observed reviewer blocker:** evidenced by a linked maintainer review; not necessarily detected by the bot.
- **Additional recommendation:** your own relevant reasoning, explicitly separated from marketplace policy.

Trace input all the way to use. Do not call a post-buffer truncation a byte limit, a pathname check a retained identity, or a mutable sidecar hash an independent trust anchor. Do not hide code/documentation, rename runtime files to avoid scanning, remove truthful permission disclosures, or weaken protections to achieve a green result.

When the user requests preparation/fixes, make scoped reversible edits and verify them. For audit-only requests, report without editing. Preserve the intended feature; explain any feature change required to satisfy a reviewed boundary instead of silently deleting functionality. Do not edit host desktop configuration or run installers merely to inspect a submission. Keep this AI skill outside the distributed Omarchy plugin: reviewers have rejected agent-control material inside plugin payloads.

Use focused behavioral checks for actual risks: over-limit stdout **and stderr**, stalled descendants, symlink/FIFO/path replacement, secret transport, malicious markup, digest mismatch, or fallback failure, as applicable. Re-audit every alternate path after a fix. Record tests actually run and limitations; never invent live hardware/runtime results.

## Assemble the review snapshot

Finish code, tests, docs, version changes and CI pins before refreshing remote validation. Inspect local changes and distinguish local HEAD from the GitHub default-branch HEAD. Commit/push only within the user's authorization. Record the full 40-character published SHA; a local-only fix is not reviewable remotely.

When a fix lands in a separately published companion package, release it first: publish the new version (usually the author's own registry action), confirm the registry serves it and its archive contains the fix, then bump the plugin's pin, push, and refresh the issue. A pin to a version that does not exist yet is not reviewable.

Keep the default branch stable during review; ongoing development can continue on a separate branch. Any published change, including README-only changes, requires fresh evidence. Do not freeze the branch by changing GitHub protection settings.

Re-run `scripts/readiness-check.sh` against the final commit, then run available static validation from requirements.md. A local preflight is advisory and does not replace bot-authored evidence. Runtime testing requires an appropriate authorized test environment; cloning/enabling an Omarchy plugin can change the active shell.

Produce a concrete review packet outside the distributable plugin:

- Readiness report: repository, full SHA, marketplace policy revision, checks/results, remaining blockers, and review capabilities with reasons and boundaries.
- Completed issue title/body from [the template](assets/submission-body.md), or a minimal proposed edit to the existing issue preserving its content and checklist.
- Concise maintainer notes covering setup, privileges, network/secret handling, persistent writes/removal, immutable dependencies, and relevant test evidence. Include only applicable facts.

Mark readiness as **blocked**, **ready for maintainer review**, or **published (verified remotely)**. A legitimate installer/package/service capability can require review even with no security finding; don't label that capability a bug.

## Submit and follow up

For new listings, preserve all six form headings and exact checklist language. Check ownership/asset rights and other declarations with the owner; do not infer those personal declarations from a public repository. Show the completed packet before creating an issue. Reuse explicit authorization and confirmations already given; otherwise obtain them only after the packet is concrete. The upstream AI submission instructions require owner confirmation and approval. A request to create this skill is not permission to post a submission or comment.

When authorized, use structured GitHub tools or `gh issue create --body-file` (see requirements.md). Never fabricate bot reports, apply maintainer approval labels, or treat successful issue creation as publication.

For an open submission after fixes, edit its body to refresh validation; preserve all sections and add the final full SHA in maintainer notes. A comment or `/validate` does not retrigger it. Verify that current default HEAD, validation, and decoded baseline all refer to the same full SHA, and that the run completed under the current policy. Do not repeatedly edit while a run is pending. If a complete refresh fails, diagnose the actual report; do not spam retries.

The maintainer must approve the current evidence with `approved-and-verified`. Do not treat a leftover approval label as proof of deployment. If registration succeeded but deployment/finalization failed, follow that phase's failure guidance instead of creating another submission.

For listed plugins use `verify-plugin.yml`: choose newer-upstream publication for a new HEAD, or existing-snapshot verification for exactly `listingValidatedCommit`. Refresh `VERIFICATION.md`; these are distinct authorization/evidence paths.

Finish with artifact links, fixes and tests, remaining work, and the exact next step. When awaiting a maintainer, say so and stop; don't promise automatic approval or unrequested indefinite monitoring.
