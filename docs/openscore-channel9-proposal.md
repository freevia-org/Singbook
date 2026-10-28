# OpenScore compatible-channel proposal

This is an unmerged draft proposal based on public main
`c77b221f1575236923b22dcea0f6672887bf11af` plus the exact reviewed adapter
commits from PR205 (`66d9f19`, `7066213`, `a23beba`). The adapter files match
that source dependency exactly. The last amendment records document rights as
unknown and scopes CC0 to the publisher's contributed corpus; its retained-response
replay preserves both canaries' body, metadata, attribution and original bytes.
The reader repair in PR206 is separate and is not included. Release 43's
version, signing, package identity and verified artifacts are unchanged.

The proposed compiled registry includes OpenScore Lieder and selects a new
`config/source-catalog-v9.json`, revision 21. All 30 v8 source rows are copied
unchanged; the added OpenScore row is disabled and off by default. Its two
future search probes identify the already qualified German/French examples
and require composition credits, language and source provenance. Disabled
probes do not run live. No current-main registry or served catalog is changed
by preparing this branch.

Channels 1–8 remain byte-exact. The new cache is `sourceCatalog:v9`; the
older v8 cache joins the existing closest-first offline fallback sequence.
The bootstrap no longer stops reading old caches at the hardcoded channel-8
ceiling. It still derives the bounded loop from the compiled cache constant,
not network input. Earlier caches are read without rewriting them. Existing
provider opt-outs, retired sources, saved documents and original source data
keep their existing migration rules. Unknown native IDs still fail before
live/cache mutation; no disabled-native allowlist or schema relaxation is added.

The focused tests cover all historical file hashes, the preserved v8 roster,
the compiled/declared v9 roster, disabled/default behavior, rejected v8-runtime
downloads with either disabled or active OpenScore, atomic unknown-ID rejection,
zero-HTTP offline maintenance, closest v8 cache fallback, saved-library reopening
and an explicit opt-out surviving a hypothetical later activation. Historical
v8 tests simulate a v8 registry rather than claiming full-current coverage.

Local verification is SDK-free Python structural checking and diff review.
Flutter/Dart tests and analysis are written but not run in this worktree under
the coordinator's no-SDK instruction. Hosted checks qualify only their recorded
PR head; results before the rights amendment do not qualify the amended head.
No local device, build, source HTTP, credentials, cloud task or schedule is used.
This proposal requires passing exact-head hosted checks and coordinator review
before integration.

Prior native qualification belongs to source `66d9f19` plus reader `1eb30e8`;
the cancellation amendment has its own final-head replay and concurrency tests.
The new compiled registry/cache migration has not been tested on a device.
No cloud proof is claimed. Before activation, review per-work rights, incomplete
plaintext availability, compatible release and default/opt-out behavior. CC0
corpus attribution does not independently clear underlying poems/translations.
The old production latest reports remain production evidence; candidate receipts
must stay separate. The main maintenance guide should advance its active-channel
table/default only when this proposal is integrated by its owner.
