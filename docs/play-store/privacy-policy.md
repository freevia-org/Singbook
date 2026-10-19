# Singbook Privacy Policy

**Effective date:** 17 October 2026
**App:** Singbook (Android package `org.freevia.singbook`), version 0.2.1
**Publisher:** Freevia EOOD, contact privacy@freevia.org
**Policy URL:** https://freevia.org/singbook/privacy/

## 1. Summary

- Singbook is a local-first songbook. Your songs, setlists and settings are stored on your device.
- Singbook has **no server, no Singbook accounts, no advertising and no analytics**. The publisher does not receive, collect or store your data.
- When you search for songs or open one, the app contacts third-party song sources **directly from your device**. Those services receive your search terms and your IP address (section 3).
- Signing in with Google for Drive sync is optional (section 5). It uses a private app-data folder by default; on Android you may choose a visible Drive folder. The publisher never receives your synced data.
- YouTube Music requests include a fixed anonymous accept-all consent marker. Singbook does not open Google's consent page, use an account or read saved browser cookies (section 3).

## 2. Data stored on your device

Singbook stores the following only on your device, in the app's private storage:

- Your song library: lyrics, chords, notes, timing data, source links, attribution and rights notes, kept in a local SQLite database and as ChordPro content.
- Setlists, favourites, and app settings (theme, palette, language, reader text size, enabled sources).
- Temporary files and caches (for example cached source responses, PDF export files). These are excluded from Android backup.

Android Auto Backup / device transfer may copy the app's library and preferences (including, if you used Google Drive sync, the Google account identifier, e-mail address, profile photo URL and hashed library binding, plus the sync bookkeeping that records which items were synced) to your Google account backup or to a new device if you have Android backup turned on in system settings. That backup is handled by Google and Android under your device settings, not by the publisher.

Files you import, export, print or share leave the app only when you choose to (for example through the Android share sheet or a PDF you save). Singbook does not read other files or your contacts, location, camera, microphone or device photo library. The only declared Android permission of consequence is `INTERNET` (to reach the sources in section 3); the app also uses the normal network-state permission added by its networking library.

## 3. Data sent to third-party sources

There is no Singbook backend. When you search for a song, open a song, or when the app looks up metadata, the app on your device makes HTTPS requests to the services below. Which of them are contacted depends on which sources are enabled and which songs you open; some are only contacted on demand.

What each service can receive: the **search text or the song title/artist/album/duration you looked up**, standard request information such as your **IP address**, device network details, and a User-Agent header of the form `Singbook/<version>` (with the publisher's contact URL if configured). Singbook does not send your library, your name, email address, device identifiers or advertising identifiers to these services, and it does not log in to them (except the token below).

| Host | Purpose |
| --- | --- |
| `api.genius.com`, `genius.com` | Song catalog search and song details; lyrics page text. Requests include the app's Genius client access token (application configuration, not your credential). |
| `www.songsterr.com` | Chord sheet and song data lookup. |
| `www.ultimate-guitar.com`, `tabs.ultimate-guitar.com` | Public chord sheet lookup. |
| `lrclib.net` | Plain and time-synchronised lyrics. |
| `music.youtube.com` (and Google image hosts such as `i.ytimg.com`, `*.googleusercontent.com` for artwork) | Song matching, lyrics shelf, artwork. Exact Music homepage/JSON requests include the fixed anonymous `SOCS=CAI` accept-all consent marker; artwork requests do not. No saved browser or account cookies are used. |
| `lyrics.ovh`, `api.deezer.com` (and Deezer image hosts) | Lyrics and song suggestions with album, duration and artwork. |
| `synclrc.dev` | Synchronised lyric search. |
| `better-lyrics.boidu.dev` | Cached word-timed lyrics (TTML). |
| `musicbrainz.org`, `www.wikidata.org`, `commons.wikimedia.org` (and `upload.wikimedia.org`), `en.wikisource.org` | Recording, work and artwork metadata; optional public-domain text. |
| `raw.githubusercontent.com`, `github.com` | Open-licensed WorshipCommons catalogue. |
| `seanmcgrathmusic.com`, `filksongbook.com` | Open-licensed songs. |
| `www.chordie.com` | Chord sheet lookup. |
| Artwork and media link hosts | Cover art may be downloaded from the provider's own image host and shown in the app. Playback links open in your browser or another app only when you tap them. |

Ozbcoz and Worship Together are import-only: Singbook does not contact them automatically; you download a file yourself and import it.

YouTube Music is an unofficial web integration. The fixed `SOCS=CAI` request marker represents an accept-all cookie choice, not a neutral or rejection choice. It is identical for every request, contains no account or device identifier, is not saved to a browser cookie store, and is sent only to `https://music.youtube.com` homepage/JSON endpoints. Singbook does not open Google's consent page, sign in, or read saved browser cookies. Google may still return a consent interstitial, challenge, regional restriction or unavailable response; Singbook reports that source failure. Availability can change at any time.

These services are independent of the publisher and have their own privacy policies and terms; they may log requests, and your IP address reveals an approximate location. Singbook does not control what they do. You can reduce exposure by turning off sources you do not want (where the app offers that setting) and by not searching.

Singbook sends no data to any other server. Tapping a link in the app opens it in your browser, governed by that site's policy.

## 4. No tracking, ads or analytics

Singbook contains no advertising SDKs, analytics or crash-reporting services, does not use advertising IDs, does not build profiles and does not sell or share personal data. The publisher does not receive data from the app.

## 5. Google sign-in and Drive sync (optional)

Singbook can offer sign-in with Google to sync your library between your own devices. It is available only in builds configured for it, is off until you tap Connect, and Singbook works fully without it.

- Sign-in happens only when you request it. After a successful connection, the app syncs your library; after that it automatically syncs when you add, edit or remove a song. Rapid changes are grouped into one sync. You can also tap Sync now. If you switch Google accounts, sync waits for your choice about how to handle the libraries. Starting the app or returning to it does not start Google authorization or cloud sync. You can disconnect at any time.
- The default sync scope is `https://www.googleapis.com/auth/drive.appdata`, which gives access to a hidden folder reserved for Singbook in **your own** Google Drive. On Android, if you choose a visible folder or pick a ChordPro file, Google Picker uses the narrower `https://www.googleapis.com/auth/drive.file` scope and grants access to the folder or files you select and the files Singbook creates. Singbook does not request permission to browse all of Drive.
- What is stored there: each synced song as a ChordPro file (lyrics, chords, notes, timing data, source links, attribution, rights notes and Singbook sync metadata), each setlist, and small sync records. The files count toward your Google storage. If the same song was changed on two devices, both versions are kept as separate copies rather than overwritten. In a visible folder, you can delete or manage these files directly in Google Drive; deleting a synced file is synchronized to your other devices after the app checks for incomplete listings.
- What the app receives from Google: your account identifier, email address, profile photo URL and authorization for the private app-data folder or the specific visible folder/files you select. The email and photo are shown in the app so you can see which account is connected. The account identifier, email and photo URL are remembered in the app's private settings to restore an existing authorization and show the account avatar; disconnecting clears that remembered session. The photo is loaded from Google's image host for display. Sign-in uses Google's libraries on your device; access tokens are held by Google and Android on your device, are not written into your song files and are never sent to the publisher.
- There is no Singbook server. Your songs travel only between your devices and your own Google account, under Google's privacy policy. The publisher cannot access your Drive data or your Google account.
- Singbook's use and transfer to any other app of information received from Google APIs will adhere to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements. Data from Google APIs is used only to provide the sync feature you asked for: it is not used for advertising, not sold, not transferred to third parties and not read by people.
- To stop syncing, disconnect (sign out) in the app. To remove the stored cloud copy and the app's access, see section 7.

## 6. Legal basis and your rights

Because the publisher does not receive or store your data, there is normally no personal data held by the publisher to access, correct or delete. Data on your device is under your control. If you are in the EEA, UK or another region with data protection rights, you may contact privacy@freevia.org with any request; the publisher will explain what, if anything, it holds. Your rights toward the third-party services in section 3 are exercised with those services.

## 7. Deleting your data

- **Local data:** delete a song or setlist in the app, clear the app's storage in Android Settings, Apps, Singbook, Storage, **Clear data**, or uninstall Singbook.
- **Android backup:** manage or delete backups in Android Settings, Google, Backup.
- **Google Drive data (only if you used sync):** disconnect (sign out) in the app. Remove the app's access through Google Account, Security, Your connections to third-party apps and services (myaccount.google.com/linkedapps), select Singbook, then Remove access. For the default hidden location, delete Singbook's hidden app data in Google Drive Settings > Manage apps. For a visible folder, delete the synced files or folder directly in Drive. Your local songs are not affected and stay on your device.
- **Exported files and shares:** files you have exported or sent to others are outside the app's control and must be removed by you.

## 8. Security

Network requests use HTTPS only; Singbook refuses plain-HTTP source requests and only follows redirects within the same site. Imported and downloaded song text is parsed as data and never executed. Local data is protected by Android's app sandbox; Singbook does not add its own encryption of the local database. No method of electronic storage is perfectly secure. If you use Drive sync, data in transit and at rest in your Drive is protected by Google's security; Singbook keeps sign-in tokens out of its own database and files.

## 9. Children

Singbook is not directed to children under 13 (or the minimum age in your country) and is not designed to attract them. The app collects no personal information from anyone, including children. Searches are sent to third-party music sources whose content may be unsuitable for young users.

## 10. Copyright and content

Singbook does not host lyrics or chord sheets. Text appears because you ask your device to fetch it from third-party sources. Copyright owners can send content questions or removal requests to privacy@freevia.org; the publisher cannot remove text from third-party sources or from other people's devices, but will review and act on reports regarding the app, including source availability.

## 11. Changes

The publisher may update this policy when the app or its sources change. The effective date above shows the current version; material changes will be described in the app's release notes.

## 12. Contact

Freevia EOOD, privacy@freevia.org

---

## Bulgarian (Български) - кратко резюме

*Това е кратко резюме. Пълната политика на английски език е по-горе.*

- Singbook пази библиотеката ви (песни, сетлисти, настройки) само на вашето устройство. Няма сървър на Singbook, профили, реклами или анализи. Издателят не получава ваши данни.
- Когато търсите или отваряте песен, устройството ви се свързва директно (HTTPS) с външни източници (Genius, Songsterr, Ultimate Guitar, LRCLIB, YouTube Music, Lyrics.ovh/Deezer, SyncLRC, Better Lyrics, MusicBrainz, Wikidata, Wikimedia, GitHub за WorshipCommons, seanmcgrathmusic.com, filksongbook.com, Chordie). Те получават думите за търсене и IP адреса ви и имат собствени политики.
- Вход с Google за синхронизиране с Drive е по избор. По подразбиране песните и сетлистите се пазят в скритата папка на приложението (`drive.appdata`) във вашия Google Drive; в Android можете да изберете видима папка. Google Picker дава на Singbook достъп само до избраната папка или файлове и създадените от приложението файлове. Издателят няма достъп. Спиране: излезте в приложението; изтрийте скритите данни от Google Drive или файловете във видимата папка.
- Изтриване: изтрийте песни в приложението, "Изчистване на данните" в Настройки на Android, деинсталирайте приложението, или (при синхронизиране) изтрийте данните на приложението от Google Drive.
- Приложението не е предназначено за деца под 13 г. и не събира лични данни.
- Контакт: privacy@freevia.org

## Ukrainian (Українська) - короткий виклад

*Це короткий виклад. Повний текст політики англійською мовою наведено вище.*

- Singbook зберігає вашу бібліотеку (пісні, сетлисти, налаштування) лише на вашому пристрої. Немає сервера Singbook, облікових записів, реклами чи аналітики. Видавець не отримує ваших даних.
- Коли ви шукаєте або відкриваєте пісню, пристрій напряму (HTTPS) звертається до сторонніх джерел (Genius, Songsterr, Ultimate Guitar, LRCLIB, YouTube Music, Lyrics.ovh/Deezer, SyncLRC, Better Lyrics, MusicBrainz, Wikidata, Wikimedia, GitHub для WorshipCommons, seanmcgrathmusic.com, filksongbook.com, Chordie). Вони отримують пошукові слова та вашу IP-адресу й мають власні політики.
- Вхід через Google для синхронізації з Drive необов'язковий. За замовчуванням пісні та сетлисти зберігаються у прихованій папці застосунку (`drive.appdata`) у вашому Google Drive; в Android можна вибрати видиму папку. Google Picker надає Singbook доступ лише до вибраної папки або файлів і створених застосунком файлів. Видавець доступу не має. Зупинити: вийдіть у застосунку; видаліть приховані дані з Google Drive або файли у видимій папці.
- Видалення: видаліть пісні в застосунку, "Очистити дані" в налаштуваннях Android, видаліть застосунок або (у разі синхронізації) видаліть дані застосунку з Google Drive.
- Застосунок не призначений для дітей до 13 років і не збирає персональних даних.
- Контакт: privacy@freevia.org
