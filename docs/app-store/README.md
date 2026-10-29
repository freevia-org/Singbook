# Singbook App Store source packet

This directory preserves listing copy, a preparation record, and genuine iOS
simulator screenshots. It is **not** a record of the currently selected App Store
Connect build or review state. Check those in App Store Connect before editing a
listing or submission.

| Material | Recorded source | Use |
| --- | --- | --- |
| `metadata/en-US/` | Listing source copy; `review_notes.txt` identifies itself as a draft for 0.2.21+35 | Compare each claim and reviewer step with the selected signed build before pasting it into App Store Connect. |
| `submission.json` | Preparation target 0.2.22+36 | Historical planning and screenshot hashes, not the current submission. |
| `screenshots/en-US/` | Native iPhone and iPad simulator captures from 0.2.9+23 | Preserve their stated provenance; do not label them as captures of a later build. |

At source commit `dc59d732` on 29 October 2026, `pubspec.yaml` had already moved
to 0.2.32+46. This source version alone does not establish which binary Apple has
selected. `python scripts/check-app-store.py` deliberately reports metadata
version drift while the historical `submission.json` remains unchanged. Do not
make that check pass by changing version numbers or screenshot provenance without
qualifying a real replacement packet.

Draft [PR #230](https://github.com/freevia-org/Singbook/pull/230) prepares new
key-picker, transposition, and setlist captures. Its first Mac simulator run
produced no images because CoreSimulator failed before the app test. The
temporary workflow is disabled; it must remain on hold until the Mac runtime and
exact next candidate are cleared. A matching source SHA and version are necessary
capture inputs, but they do not prove parity with an App Store signed binary.

For the next editable listing: verify Apple's selected version/build and review
state; compare the copy with that build's tested features; capture and visually
inspect its actual iPhone/iPad workflows; record device, source, build, dimensions,
and hashes; then update the screenshot gallery and reviewer notes. Keep the
in-review version and legal agreements untouched during this source preparation.
