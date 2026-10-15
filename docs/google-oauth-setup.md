# Google Cloud setup for Singbook Drive sync

Owner checklist for turning on Google Sign-In and Drive sync. Singbook has no
backend and no client secret: the only things you create are a Google Cloud
project, an OAuth consent screen and OAuth **client IDs** (public identifiers).

What the app needs (from `lib/sync/google_auth.dart`):

- Scope: `https://www.googleapis.com/auth/drive.appdata` only (hidden per-app
  Drive folder; the app cannot see any other Drive file).
- Dart define `VERSE_GOOGLE_SERVER_CLIENT_ID`: the **Web application** client ID
  (required by Google Sign-In on Android).
- Dart define `VERSE_GOOGLE_IOS_CLIENT_ID`: only for an iOS build (optional;
  iOS is not validated by the Android build).
- Android package name `org.freevia.singbook`.

For how the sync itself works (in-place files, three-way compare, conflict
copies) see [`lib/sync/SETUP.md`](../lib/sync/SETUP.md).

> Verification notes. UI labels below were checked against Google's current
> Cloud Help pages on 2026-10-15 (Audience, Branding, Data Access, Clients
> articles of the "Google Auth Platform"). Where a label could not be confirmed
> it is marked **(unverified)**. Google renames console items from time to time;
> if a label differs, look for the item with the same meaning.

## 0. Facts that decide how much work this is

| Fact | Source / status |
| --- | --- |
| `drive.appdata` is listed as a **non-sensitive** scope ("View and manage the app's own configuration data in your Google Drive"). | Drive API "Choose Google Drive API scopes" page, checked 2026-10-15. |
| Verification is required for apps using **sensitive or restricted** scopes; apps using only non-sensitive scopes are not required to verify. | Google Cloud Help, "OAuth App Verification Help Center" (answer 13463073), checked. |
| *Brand verification* (so your app name/logo shows on the consent screen) applies to External apps in production that display a logo or app name. Without it, users see only the app domain. Not mandatory for the app to work. | Google Cloud Help, answer 13463073 and Branding article (answer 15549049). Exact on-screen wording for an unverified-brand consent screen: **(unverified)**. |
| In **Testing** status: max **100 test users**, and "Authorizations by a test user will expire seven days from the time of consent" (refresh tokens too). Users must be listed as test users. | Audience article (answer 15549945), checked. Exception for `openid`/email/profile-only requests does not apply: Singbook requests the Drive scope. |
| The 100-new-user cap on *unverified* apps applies for the project's lifetime and cannot be reset. The cap does not apply to apps that only request approved sensitive/restricted scopes. For a non-sensitive-only app, whether the unverified-app cap is shown or enforced in Production **(unverified)** from Google text. Watch the Google Auth Platform Verification Center / Audience page for a user-count meter after launch. | Audience article, partly. |
| Google API Services User Data Policy (Limited Use) is documented under sensitive/restricted scopes; the page does not say it exempts other scopes. Treat it as applicable. | Google API Services User Data Policy; see the public [privacy policy](play-store/privacy-policy.md). |

Conclusion: set the consent screen to **External**, add the single
non-sensitive scope and publish to **In production**. No verification review
should be needed for the scope itself; optional brand verification needs a
verified domain, homepage and privacy policy on that domain.

## 1. Create the project and enable the Drive API

1. Open <https://console.cloud.google.com/> signed in with the Google account
   that will own the project (use a long-lived owner account, not a personal
   throwaway).
2. Project picker (top bar), **New project**. Name it `Singbook`. Create it and
   make sure it is selected.
3. **APIs & Services > Library**, search `Google Drive API`, open it and click
   **Enable**. (Data Access lists scopes only for APIs that are already enabled.)

## 2. Google Auth Platform: branding, audience, scopes

Open **Google Auth Platform** (search for it in the console search bar). On a
fresh project it shows a **Get started** wizard; if the console instead shows
"OAuth consent screen" with a User Type choice, you are on the older layout
and the same fields apply.

### Overview wizard / Branding

- App name: `Singbook`. Must not be confusable with Google brands.
- User support email: an address you monitor. It must be your own Google
  account email or a Google Group you manage.
- App logo (optional, max 1 MB, square, ideally 120x120). A logo only appears
  after brand verification and **changing it later triggers re-verification**;
  skip it unless you want brand verification.
- App domain: homepage URL, **Privacy policy link**, optional Terms of service.
  Homepage and privacy policy must be on a domain you own, and the homepage must
  link the privacy policy. Required for external production apps that undergo
  brand verification; host `docs/play-store/privacy-policy.html` and use that
  same URL here as in Play Console.
- **Authorized domains**: add the privacy-policy domain **before** entering URLs
  that use it (Google: add authorized domains before the homepage/privacy URLs).
- Developer contact information: an email you read (Google sends project
  notices there).

### Audience

- User type: **External** (Internal needs a Google Cloud organization and
  excludes ordinary Gmail users).
- Publishing status shown here is Testing initially. Add your own accounts
  under **Test users** while developing (see section 7 for the limits).

### Data Access

1. **ADD OR REMOVE SCOPES**.
2. Select `.../auth/drive.appdata` (or paste it under **Manually add scopes** if
   it is not listed), click **UPDATE**.
3. Confirm it appears under **Non-sensitive scopes** in the table. If it shows
   up as Sensitive/Restricted, stop: you picked a different scope (for example
   `drive` or `drive.file`), which would trigger verification.

Do **not** add any other scope. The app does not need `email`/`profile` to be
listed; Google Sign-In identifies the account with basic profile information.

### Publish to Production

1. **Audience > Publish app** (button label per Google's Audience article).
   Confirm the dialog. Status becomes **In production**.
2. Do this before shipping builds to anyone other than the test users listed;
   otherwise the 100-user / 7-day-expiry limits apply.
3. If the console offers **Verify Branding**, it is optional. If you start it,
   publish the branding within 7 days or the status reverts to "Need to
   re-verify" (Branding article). Data-access verification is not needed for a
   non-sensitive scope.

## 3. Collect the signing certificate SHA-1s

Android OAuth clients are matched by **package name + signing-certificate
SHA-1**, so you need one client per certificate that signs an installed build:

| Build | Certificate | Where to get the SHA-1 |
| --- | --- | --- |
| Development (`flutter run`, debug APK) | `~/.android/debug.keystore` | `scripts/print-signing-fingerprints.ps1` |
| Local release APK / sideloading with the upload key | Freevia upload key | SHA-1 `A9:90:B6:7B:D5:ED:29:C1:CF:28:AC:8E:2C:B8:21:03:1A:53:BD:BB` (SHA-256 `6D:1C:36:39:7B:7F:BF:1C:44:8F:0B:A9:85:9E:B8:7D:C8:5B:B5:21:9B:7C:96:7D:52:C5:1A:5F:85:98:76:21`); also from the script |
| Installs from Google Play | **Play app-signing certificate** (Google re-signs the app) | Play Console > your app > **Test and release > App integrity > App signing** (older consoles: Setup > App signing). Copy the SHA-1 of the *App signing key certificate*. Exact menu path **(unverified)**; the release checklist uses "App integrity". |

Run `pwsh scripts/print-signing-fingerprints.ps1` to print the debug and upload
fingerprints without exposing passwords. The Play app-signing SHA-1 exists only
after the app has been created in Play Console and Play App Signing enrolled,
which happens at the first internal-testing upload; so the first Play-signed
build cannot be tested before that client is added. Plan one throwaway
internal-test upload.

## 4. Create the OAuth clients

**Google Auth Platform > Clients > CREATE CLIENT.** For each client choose the
application type, fill it in and click **CREATE**.

Create these:

1. **Android, debug.** Application type: Android. Name: `Singbook Android debug`.
   Package name: `org.freevia.singbook`. SHA-1: the debug keystore SHA-1.
2. **Android, upload key.** Name: `Singbook Android upload`. Package name
   `org.freevia.singbook`. SHA-1 `A9:90:B6:7B:D5:ED:29:C1:CF:28:AC:8E:2C:B8:21:03:1A:53:BD:BB`.
3. **Android, Play app signing.** Name: `Singbook Android Play`. Package name
   `org.freevia.singbook`. SHA-1: from Play Console (section 3).
4. **Web application.** Name: `Singbook web (server client ID)`. No redirect URIs
   or JavaScript origins are needed. Copy its **Client ID**
   (`<number>-<hash>.apps.googleusercontent.com`) - this becomes
   `VERSE_GOOGLE_SERVER_CLIENT_ID`. Google shows a client secret once; the app
   does not use it, so do not store it in the repository or the app.
5. **iOS (optional, only for a future iOS build).** Application type: iOS, Bundle
   ID of the iOS app. Its client ID becomes `VERSE_GOOGLE_IOS_CLIENT_ID`.

The Android clients themselves never appear in the app's configuration: Google
matches the running APK to them by package name and certificate. Leave the
optional "Verify ownership" setting off unless you know you need it.

Allow a few minutes (Google says changes can take several minutes, sometimes
longer, to take effect) before testing.

## 5. Put the values in the build configuration

Edit `config/local.defines.json` (git-ignored; never commit it, never paste it
into chats). Start from `config/defines.example.json`:

```json
{
  "GENIUS_ACCESS_TOKEN": "<genius client access token>",
  "VERSE_GOOGLE_SERVER_CLIENT_ID": "<web client id>.apps.googleusercontent.com",
  "VERSE_GOOGLE_IOS_CLIENT_ID": "",
  "SINGBOOK_CONTACT_URL": ""
}
```

Leave `VERSE_GOOGLE_IOS_CLIENT_ID` empty for Android-only builds. Both IDs must
end in `.apps.googleusercontent.com` or the app treats Google sign-in as not
configured.

Rebuild (a Dart define is compiled in; hot reload will not pick it up):

```powershell
.\scripts\build-android.ps1 -Debug                    # emulator / device
.\scripts\build-android.ps1 -Bundle -Production       # Play AAB, after the Play client exists
```

Configure OAuth **before** the release AAB build: a build made without the
define ships with sync disabled.

## 6. Verification checklist

- [ ] APIs & Services shows Google Drive API enabled.
- [ ] Data Access lists exactly `drive.appdata`, under Non-sensitive.
- [ ] Audience: External, status **In production** (or your accounts are listed
      as test users while developing).
- [ ] Android clients exist for debug, upload and Play app-signing SHA-1s, all with
      package `org.freevia.singbook`.
- [ ] The web client ID is in `config/local.defines.json` and the app was rebuilt.
- [ ] Emulator test: use an AVD **with the Google Play system image** (not
      "Google APIs" only or AOSP), signed into a Google account in Settings.
      Install the debug build, open the app's account/sync settings, tap Connect, pick the
      account, accept the Drive "app data" consent.
- [ ] Add/edit a song, sync, and confirm the status shows success.
- [ ] Second device (phone or second emulator) signed in with the same Google
      account: Connect, sync; the song and setlist appear.
- [ ] Edit the same song on both devices while offline, sync both: one is kept
      and the other appears as a conflict copy (no silent loss).
- [ ] Disconnect in the app; confirm sync stops; reconnect works.
- [ ] Repeat the sign-in on a **release build installed from Play internal
      testing** (this exercises the Play app-signing SHA-1 and R8).

## 7. Testing-mode limits (why sign-in "stops working after a week")

While publishing status is **Testing**:

- Only accounts listed under Audience > Test users can sign in (max 100).
- Authorization expires seven days after consent; the user must reconnect.
- Consequently, closed-testing testers from Play must be test users or the
  app must be In production.

Moving to **In production** removes the test-user requirement and the 7-day
expiry for Drive scopes. A non-test Google account may still see an
"unverified app" screen if the project has not passed brand/OAuth verification;
this is cosmetic for a non-sensitive scope **(unverified: confirm on a real
non-test account after publishing)**.

## 8. Troubleshooting

| Symptom | Likely cause and fix |
| --- | --- |
| Error 10 / `DEVELOPER_ERROR` / 12500 / `clientConfigurationError`, or sign-in sheet closes immediately (reported as `canceled`) | Package name or **SHA-1 of the signing certificate does not match any Android OAuth client**, or the web client ID is wrong. Compare the installed APK's certificate: `scripts/print-signing-fingerprints.ps1` (debug/upload), Play Console (Play installs). Works on debug but not on Play = missing Play-signing client. Wait a few minutes after creating a client. The plugin notes that Credential Manager can return `canceled` for configuration problems and cannot tell them apart from a user cancel. |
| "serverClientId must be provided on Android" | `VERSE_GOOGLE_SERVER_CLIENT_ID` missing from the build: rebuild with `--dart-define-from-file=config/local.defines.json`. |
| App shows Google sign-in as not configured | Defines absent or the ID does not end in `.apps.googleusercontent.com`. |
| "Access blocked: this app has not completed the Google verification process" / account not allowed | Consent screen is in Testing and the account is not listed under Test users, or the 100-user limit was reached. Add the account or publish to Production. |
| Worked last week, now asks to sign in again | Testing mode: 7-day authorization expiry. Publish to Production. |
| "Access blocked: Authorization Error", scope not allowed | A different scope is requested than the one on Data Access, or the Drive API is not enabled in the project. |
| No Google account or sign-in sheet on an emulator | The AVD image has no Google Play services (AOSP / "Google APIs" without Play Store) or no Google account is signed in. Use a "Google Play" image and add an account under Settings. |
| Sign-in works but sync fails with 403 `accessNotConfigured` / "Drive API has not been used in project" | Drive API not enabled in the project that owns the web client. Enable it (section 1). |
| Sign-in fails only on release builds | Play-signing SHA-1 client missing, or R8 stripped something; reproduce with the release-signed APK built by `build-android.ps1 -Production` and check logcat. |
| Account picker never lists the intended account | Device account not present, or Credential Manager is disabled for the work profile; add the account to the primary profile. |

## 9. Values the owner must supply

1. Google account that owns the Cloud project.
2. Support email and developer contact email.
3. Public privacy-policy URL (and homepage if you want brand verification).
4. Play app-signing SHA-1 from Play Console (after the first internal upload).
5. The Web client ID (to `VERSE_GOOGLE_SERVER_CLIENT_ID`).
6. iOS bundle ID/client ID only if iOS is built.
