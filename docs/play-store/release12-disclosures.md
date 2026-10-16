# Release 12 Play disclosures

Prepared against integrated runtime `d186b7b`; apply only to the accepted
0.2.0+12 release. These instructions contain no credentials. Retain the
existing dedicated review account and keep partner testing/feedback off.

## App access: optional Google Drive sync

Replace the instructions only; keep saved account credentials unchanged.

```text
All song features work without sign-in. Drive sync is optional. Open Account and sync using the top-right cloud/account button. Sign in with Google using the dedicated review account above. Connecting syncs the library; adding, editing or deleting a song then syncs automatically. Sync now also syncs songs and setlists. Startup and app resume do not sign in or sync. Sign out to stay local. If switching accounts, choose how to handle the libraries. No payments or subscriptions.
```

## Default English listing

Replace only the paragraph under `OPTIONAL GOOGLE DRIVE SYNC`. Keep the
remaining accepted store description, screenshots and contact details.

```text
Sign in with Google only if you want to back up and sync your songs and setlists between your own devices. Singbook uses a private, hidden folder in your Google Drive and cannot access your other Drive files. Connecting syncs your library. After that, adding, editing or removing a song triggers another sync; rapid changes are grouped. Sync now also syncs songs and setlists. Setlist-only changes wait for the next sync. Starting or returning to the app never starts Google sign-in or cloud sync. Your connected account photo is shown in the app when available. When the same song changes on two devices, both versions are kept as copies. If you switch Google accounts, choose how to handle the libraries before syncing. Sign out to continue locally.
```

## Release notes

```text
<en-US>
Clearer search controls and song/setlist imports.
Back navigation returns to Home and supports double-Back to exit.
Your connected Google account photo appears in the header.
Optional Drive sync runs after connecting and after song changes. Startup and resume never start sign-in or sync.
YouTube Music now uses one source switch, with Google's cookie choice shown only when needed.
</en-US>
<bg>
По-ясно търсене и импорт на песни и сетлисти.
Навигацията Назад връща към Начало и поддържа двойно натискане за изход.
Снимката на свързания Google акаунт се показва в заглавната лента.
По избор: Drive се синхронизира след свързване и промени в песни. Стартиране и връщане в приложението не започват вход или синхронизация.
YouTube Music вече има един превключвател; изборът за бисквитки на Google се показва само при нужда.
</bg>
<uk>
Зручніший пошук та імпорт пісень і сетлистів.
Навігація Назад повертає до головного екрана й підтримує подвійне натискання для виходу.
Фото підключеного облікового запису Google з’являється в заголовку.
За бажанням: Drive синхронізується після підключення та змін у піснях. Запуск і повернення до застосунку не починають вхід чи синхронізацію.
YouTube Music тепер має один перемикач; вибір файлів cookie Google з’являється лише за потреби.
</uk>
```

## Data safety review

The accepted runtime keeps Google connection optional. Automatic song-change
sync changes when the same library documents are transmitted, not their data
types or destination. Setlist-only writes do not start automatic sync.

The account photo URL is received through the existing Google identity flow,
remembered in private app settings and loaded from Google for display. No
device photo-library access or photo upload is added. Android backup can copy
that remembered URL along with other preferences; the policy now names it.
Keep the existing optional email, user ID, files/docs and search-history
answers unless final runtime review identifies an additional outbound type.
This is a code-based assessment, not a claim of a completed real-account
end-to-end sign-in or YouTube consent test.

References: [Google Play Data safety definitions](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en),
[Google OpenID Connect profile picture URL](https://developers.google.com/identity/openid-connect/reference).
