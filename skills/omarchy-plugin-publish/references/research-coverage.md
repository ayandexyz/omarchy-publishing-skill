# Research coverage

Retrieved 2026-09-23. Marketplace source: [3382370f6b9a5334876d461a96335198bd0111c5](https://github.com/omacom/omarchy-plugin-marketplace/tree/3382370f6b9a5334876d461a96335198bd0111c5).

Inspected metadata for the 100 most recently updated `submission` issues, then read 41 complete comment threads selected to include the user issue, recurring blockers, complex re-reviews, and listed examples. This is not a random sample or an approval-rate study. Current labels and edited bot comments are not historical state snapshots.

Amended 2026-09-24 with one first-hand thread, [#8397](https://github.com/omacom/omarchy-plugin-marketplace/issues/8397) (Glance Face Unlock), observed live rather than sampled: a supply-chain finding against an unpinned companion-application install that the plugin executes. It is the source of the unpinned-install check in `scripts/readiness-check.sh` and the opening paragraph of the dependencies section in `review-patterns.md`. It returned a second round at the next commit -- the documented install was pinned but the plugin still auto-selected unpinned locations -- which is the source of the executable-discovery check and the paragraph beside it. At time of writing that issue is open and unresolved, so it evidences the findings, not an outcome.

Amended 2026-10-04 with a second first-hand thread, [#9941](https://github.com/omacom/omarchy-plugin-marketplace/issues/9941) (Hommies), followed live through three reviews to `approved-and-verified` (marketplace source [cdf7235a1c464e3dce572bc8e8cfbc26a4e97f88](https://github.com/omacom/omarchy-plugin-marketplace/tree/cdf7235a1c464e3dce572bc8e8cfbc26a4e97f88)). Both findings were in the pinned companion npm package, not the plugin repository: private text in `notify-send` arguments, then hook clients trusting a stale loopback `port.json`. They are the source of the process-argument paragraph in the secrets section, the loopback-client paragraph in the network section, the companion-package paragraph in the dependencies section, and the matching three heuristics in `scripts/readiness-check.sh`. Unlike #8397, this thread evidences an outcome: the fixes described were accepted.

| Issue | Title | State when fetched | Comments fetched | Maintainer comments |
| --- | --- | --- | --- | --- |
| [#2542](https://github.com/omacom/omarchy-plugin-marketplace/issues/2542) | [Plugin]: BatPuter v3.0 — Wayne Tech Tactical Productivity HUD | closed; not marked listed | 13 | 4 |
| [#4149](https://github.com/omacom/omarchy-plugin-marketplace/issues/4149) | [Plugin]: omasend | closed; listed | 34 | 14 |
| [#4280](https://github.com/omacom/omarchy-plugin-marketplace/issues/4280) | [Plugin]: Container Hub | open; not marked listed | 9 | 4 |
| [#4784](https://github.com/omacom/omarchy-plugin-marketplace/issues/4784) | [Plugin]: Cameras | closed; listed | 8 | 2 |
| [#5540](https://github.com/omacom/omarchy-plugin-marketplace/issues/5540) | [Plugin]: OmaNitro | open; not marked listed | 17 | 7 |
| [#6087](https://github.com/omacom/omarchy-plugin-marketplace/issues/6087) | [Plugin]: OmaNotes | closed; listed | 22 | 9 |
| [#6300](https://github.com/omacom/omarchy-plugin-marketplace/issues/6300) | [Plugin]: OmaTube | closed; listed | 7 | 3 |
| [#6393](https://github.com/omacom/omarchy-plugin-marketplace/issues/6393) | [Plugin]: Omarchy Watch | closed; not marked listed | 11 | 6 |
| [#6488](https://github.com/omacom/omarchy-plugin-marketplace/issues/6488) | [Plugin]: OpenCode Usage | closed; listed | 10 | 3 |
| [#6535](https://github.com/omacom/omarchy-plugin-marketplace/issues/6535) | [Plugin]: UniCast | open; not marked listed | 6 | 3 |
| [#6628](https://github.com/omacom/omarchy-plugin-marketplace/issues/6628) | [Plugin]: Hero Notification Center | open; not marked listed | 6 | 3 |
| [#6674](https://github.com/omacom/omarchy-plugin-marketplace/issues/6674) | [Plugin]: OmaCheck | open; not marked listed | 6 | 3 |
| [#6694](https://github.com/omacom/omarchy-plugin-marketplace/issues/6694) | [Plugin]: Energy Meter | closed; listed | 7 | 2 |
| [#6717](https://github.com/omacom/omarchy-plugin-marketplace/issues/6717) | [Plugin]: flatpak-explorer | open; not marked listed | 6 | 3 |
| [#7130](https://github.com/omacom/omarchy-plugin-marketplace/issues/7130) | [Plugin]: Wi-Fi Hotspot & Repeater | open; not marked listed | 6 | 2 |
| [#7145](https://github.com/omacom/omarchy-plugin-marketplace/issues/7145) | [Plugin]: omaclean — safe cleanup status for the Omarchy bar | open; not marked listed | 7 | 3 |
| [#7396](https://github.com/omacom/omarchy-plugin-marketplace/issues/7396) | [Plugin]: Android Mirror | open; not marked listed | 6 | 3 |
| [#7465](https://github.com/omacom/omarchy-plugin-marketplace/issues/7465) | [Plugin]: Omarchy Undercover | open; not marked listed | 5 | 2 |
| [#7497](https://github.com/omacom/omarchy-plugin-marketplace/issues/7497) | [Plugin]: Phonecam | open; not marked listed | 5 | 2 |
| [#7524](https://github.com/omacom/omarchy-plugin-marketplace/issues/7524) | [Plugin]: The Missing Manual | open; not marked listed | 6 | 2 |
| [#7617](https://github.com/omacom/omarchy-plugin-marketplace/issues/7617) | [Plugin]: XPS Power | open; not marked listed | 5 | 2 |
| [#7629](https://github.com/omacom/omarchy-plugin-marketplace/issues/7629) | [Plugin]: Ollama Cloud Usage | open; not marked listed | 5 | 2 |
| [#7666](https://github.com/omacom/omarchy-plugin-marketplace/issues/7666) | [Plugin]: System+ | closed; listed | 9 | 3 |
| [#7716](https://github.com/omacom/omarchy-plugin-marketplace/issues/7716) | [Plugin]: Vantage | open; not marked listed | 7 | 2 |
| [#7747](https://github.com/omacom/omarchy-plugin-marketplace/issues/7747) | [Plugin]: Lock Designs | open; not marked listed | 5 | 2 |
| [#7873](https://github.com/omacom/omarchy-plugin-marketplace/issues/7873) | [Plugin]: Musica | closed; listed | 6 | 2 |
| [#7945](https://github.com/omacom/omarchy-plugin-marketplace/issues/7945) | [Plugin]: Camera Blur | open; not marked listed | 5 | 2 |
| [#8022](https://github.com/omacom/omarchy-plugin-marketplace/issues/8022) | [Plugin]: OmaHub | open; not marked listed | 6 | 2 |
| [#8078](https://github.com/omacom/omarchy-plugin-marketplace/issues/8078) | [Plugin]: wifi-dns-ru - Wi-Fi + DNS RU widget | closed; listed | 3 | 0 |
| [#8123](https://github.com/omacom/omarchy-plugin-marketplace/issues/8123) | [Plugin]: Pear Passwords | closed; listed | 5 | 1 |
| [#8128](https://github.com/omacom/omarchy-plugin-marketplace/issues/8128) | [Plugin]: Proton Drive Sync | closed; listed | 6 | 2 |
| [#8191](https://github.com/omacom/omarchy-plugin-marketplace/issues/8191) | [Plugin]: SingularityApp | open; not marked listed | 3 | 1 |
| [#8227](https://github.com/omacom/omarchy-plugin-marketplace/issues/8227) | [Plugin]:omacal | open; not marked listed | 4 | 1 |
| [#8245](https://github.com/omacom/omarchy-plugin-marketplace/issues/8245) | [Plugin]: Penguine Network | open; not marked listed | 4 | 1 |
| [#8256](https://github.com/omacom/omarchy-plugin-marketplace/issues/8256) | [Plugin]: AppImages | open; not marked listed | 3 | 1 |
| [#8261](https://github.com/omacom/omarchy-plugin-marketplace/issues/8261) | [Plugin]: Exposé Switch | open; not marked listed | 4 | 1 |
| [#8282](https://github.com/omacom/omarchy-plugin-marketplace/issues/8282) | [Plugin]: NotebookLM Bridge | closed; listed | 5 | 1 |
| [#8291](https://github.com/omacom/omarchy-plugin-marketplace/issues/8291) | [Plugin]: Pullover | open; not marked listed | 6 | 2 |
| [#8307](https://github.com/omacom/omarchy-plugin-marketplace/issues/8307) | [Plugin]: Dock | open; not marked listed | 3 | 1 |
| [#8328](https://github.com/omacom/omarchy-plugin-marketplace/issues/8328) | [Plugin]: Taskwarrior Time | closed; not marked listed | 8 | 2 |
| [#8330](https://github.com/omacom/omarchy-plugin-marketplace/issues/8330) | [Plugin]: Omodachi | open; not marked listed | 4 | 1 |
| [#8397](https://github.com/omacom/omarchy-plugin-marketplace/issues/8397) | [Plugin]: Glance Face Unlock | open; needs-fixes | 4 | 2 |
| [#9941](https://github.com/omacom/omarchy-plugin-marketplace/issues/9941) | [Plugin]: Hommies | open; approved-and-verified, manual-setup | 6 | 3 |

The account `github-actions[bot]` supplied automated reports. `HANCORE-linux` supplied the review comments used here. Public account identity does not establish how reviews were authored. Issue #8078 provides a listed example with review-capability labels and no HANCORE prose in the fetched thread; do not infer why a maintainer approved from absence of a comment.

Several closed threads still contain historical blockers. The skill uses them as evidence of requested fixes, never as proof of current vulnerability. Some historical comments mention closing after seven days without a validated response; treat that as observed handling, not a guaranteed universal deadline.
