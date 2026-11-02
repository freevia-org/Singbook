# Microsoft Store packaging runbook

The Windows Store lane already exists; this page ties the pieces together and
lists the steps that only the owner can do. Nothing here uploads, signs, or
submits anything.

## What exists

| Piece | Location |
| --- | --- |
| Package manifest (identity `Freevia.Singbook`, reserved publisher, x64, `runFullTrust`) | `scripts/windows-store/AppxManifest.xml` |
| Packaging script (MakeAppx pack, payload hash checks, round-trip unpack, tile PNGs from `assets/branding/singbook-icon.png`, `package-provenance.json`) | `scripts/windows-store/package-msix.ps1` |
| Pinned per-release package and install smoke test | `.github/workflows/package-windows-store-release.yml` |
| Install/launch/close/reopen smoke test | `scripts/test-windows-store-msix-install.ps1`, `.github/workflows/test-windows-store-msix-install.yml` |
| Listing poster art | `docs/microsoft-store/assets/` |
| Windows CI bundle that is packaged | `windows-release-bundle` artifact from `ci.yml` |

The identity name and publisher are the values reserved in Partner Center and
are checked by the script, so they are not placeholders and need no local
config file. The MSIX is built unsigned; Partner Center signs it after
certification, so no certificate or signing key is used anywhere in this repo.

## Version mapping

Store package version is `1.0.<pubspec build number>.0`, for example pubspec
`0.2.34+48` becomes `Singbook_1.0.48.0_x64.msix`. The build number must be in
1..65535 and must exceed the number of the last submitted package.

## Packaging a new release (repo side)

1. Land the release commit on `main` and let `ci.yml` pass; note the CI run ID,
   the `windows-release-bundle` artifact ID and digest, the portable manifest
   and ZIP SHA-256 values, the source commit and its tree hash.
2. Add a release choice and a matching block in the "Resolve release pins" step
   of `package-windows-store-release.yml` (same shape as the existing blocks).
   Frozen pins are reviewed in a PR, never passed at dispatch time.
3. Run the workflow from the Actions tab for that release. It packages the
   exact CI bundle, round-trips the MSIX, and installs/launches/closes/reopens
   it. It never contacts Partner Center.
4. Download the unsigned `.msix` and `package-provenance.json` artifacts.

## Owner-only steps

- Partner Center developer account, app name reservation, and the identity
  values (`Name`, `Publisher`) shown under Product identity. They must match
  the manifest; if they change, update the manifest and the check in
  `package-msix.ps1` together.
- Upload the unsigned `.msix` to a new submission, then fill or confirm the
  listing, age rating, pricing, privacy policy URL, screenshots, and poster.
- Submit for certification, answer certification feedback, and choose the
  publication timing. Partner Center signs the package.
- Confirm the live version afterwards (Store listing and installed package
  version).

## Not covered by automation

The smoke test does not run WACK (Windows App Certification Kit), a packaged
Google sign-in lifecycle, or a locale/DPI matrix on the packaged app. Run WACK
on the candidate if certification feedback asks for it.
