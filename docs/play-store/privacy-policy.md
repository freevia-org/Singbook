# Singbook Privacy Policy

**Effective date:** 24 October 2026
**App:** Singbook (Android package and iOS bundle ID `org.freevia.singbook`)
**Publisher:** Freevia EOOD, contact privacy@freevia.org
**Policy URL:** https://freevia.org/singbook/privacy/

## 1. Summary

- Singbook is a local-first songbook. Your songs, setlists and settings are stored on your device.
- Singbook has **no publisher-operated app backend, no Singbook accounts and no advertising**. Freevia does not receive your library or provider-search requests. Third-party services and bundled components may process data as described below.
- When you search for songs or open one, the app contacts third-party song sources **directly from your device**. Those services receive your search terms and your IP address (section 3).
- Cloud sync is optional and provider-specific: Google Drive sync is available when configured; iCloud sync is available on supported Apple builds (section 5). The publisher does not receive either cloud copy.
- YouTube Music requests include a fixed anonymous accept-all consent marker. Singbook does not open Google's consent page, use an account or read saved browser cookies (section 3).

## 2. Data stored on your device

Singbook stores the following on your device, in the app's private storage. If you enable cloud sync, the selected library content and sync metadata are also copied to the provider you choose, as described in section 5:

- Your song library: lyrics, chords, notes, timing data, source links, attribution and rights notes, kept in a local SQLite database and as ChordPro content.
- Setlists, favourites, and app settings (theme, palette, language, reader text size, enabled sources).
- Temporary files and caches (for example cached source responses, PDF export files). These are excluded from Android backup.

Android Auto Backup / device transfer may copy the app's library and preferences (including, if you used Google Drive sync, the Google account identifier, e-mail address, profile photo URL and hashed library binding, plus the sync bookkeeping that records which items were synced) to your Google account backup or to a new device if you have Android backup turned on in system settings. That backup is handled by Google and Android under your device settings, not by the publisher.

Files you export, print or share go to the destination you choose through Android or iOS system interfaces. System backup and device transfer may include app data under your device settings; Android backup exclusions do not configure iOS backups. Singbook does not read other files or your contacts, location, camera, microphone or device photo library. The only declared Android permission of consequence is `INTERNET` (to reach the sources in section 3); the app also uses the normal network-state permission added by its networking library.

## 3. Data sent to third-party sources

There is no Singbook backend. When you search for a song, open a song, or when the app looks up metadata, the app on your device makes HTTPS requests to the services below. Which of them are contacted depends on which sources are enabled and which songs you open; some are only contacted on demand.

When you search, Singbook may send your query to several available song catalogs enabled in settings. It remembers your preferred catalog and shows its results first when available. Otherwise it uses the normal fallback, preferring Genius when configured and available. Wikisource searches historical texts separately and is searched only when you select it. Results that arrive without artwork may be looked up by artist and title in enabled artwork catalogs (Lyrics.ovh and YouTube Music). After you choose a song, Singbook may check enabled sources for lyrics, chords, and metadata.

What each service can receive: the **search text or the song title/artist/album/duration you looked up**, standard request information such as your **IP address**, device network details, and a User-Agent header of the form `Singbook/<version>` (with the publisher's contact URL if configured). Singbook does not send your library or Google Drive account identity to song-source services, and it does not log in to them (except the token below).

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

These services are independent of the publisher and have their own privacy policies and terms. They may retain search queries and request logs beyond the immediate response, associate requests with network/service identifiers, and derive approximate location from your IP address. Retention differs by provider. Singbook does not control what they do. You can reduce exposure by turning off sources you do not want (where the app offers that setting) and by not searching.

Source definitions can refresh from the public Singbook GitHub repository. Which integrations are available depends on the platform, release profile and user settings. The provider table covers supported integrations across builds, not a claim that every release contacts every host. Tapping a link in the app opens it in your browser, governed by that site's policy.

Singbook 0.2.16+30 and later do not read or send YouTube Music’s Google-issued VISITOR_DATA as X-Goog-Visitor-Id. Some earlier builds, including 0.2.15+29, sent that value on subsequent service requests; this legacy behavior is separate from the fixed SOCS=CAI consent marker and is not an advertising ID. Current versions still send the fixed marker to the Music homepage/JSON endpoints as described above. No signed-in browser cookies are imported. Source-catalog updates use raw.githubusercontent.com; Unison uses unison.betterlyrics.org (legacy attribution may name unison.boidu.dev). Providers may retain requests, including search terms and network information, under their policies.

## 4. No tracking, ads or analytics

Singbook has no publisher-operated advertising, analytics or crash-reporting service and does not use an advertising ID. Google’s bundled iOS sign-in SDK declares linked identifiers, contact/profile data, approximate location and usage/other data for functionality and/or analytics in its privacy manifest. These are SDK disclosures; they do not mean Freevia receives those data. App Store privacy answers account for integrated components and enabled providers. Provider policies govern their own handling, including any endpoint-specific association with other data.

## 5. Google sign-in and Drive sync (optional)

Singbook can offer sign-in with Google to sync your library between your own devices. It is available only in builds configured for it, is off until you tap Connect, and Singbook works fully without it.

- Sign-in happens only when you request it. After a successful connection, the app syncs your library; after that it automatically syncs when you add, edit or remove a song. Rapid changes are grouped into one sync. You can also tap Sync now. If you switch Google accounts, sync waits for your choice about how to handle the libraries. Starting the app or returning to it does not start Google authorization or cloud sync. You can disconnect at any time.
- The default sync scope is `https://www.googleapis.com/auth/drive.appdata`, which gives access to a hidden folder reserved for Singbook in **your own** Google Drive. On Android or macOS, if you choose a visible folder or pick a ChordPro file, Google Picker uses the narrower `https://www.googleapis.com/auth/drive.file` scope and grants access to the folder or files you select and the files Singbook creates. Singbook does not request permission to browse all of Drive.
- What is stored there: each synced song as a ChordPro file (lyrics, chords, notes, timing data, source links, attribution, rights notes and Singbook sync metadata), each setlist, and small sync records. The files count toward your Google storage. If the same song was changed on two devices, both versions are kept as separate copies rather than overwritten. In a visible folder, you can delete or manage these files directly in Google Drive; deleting a synced file is synchronized to your other devices after the app checks for incomplete listings.
- What the app receives from Google: your account identifier, email address, profile photo URL and authorization for the private app-data folder or the specific visible folder/files you select. The email and photo are shown in the app so you can see which account is connected. The account identifier, email and photo URL are remembered in the app's private settings to restore an existing authorization and show the account avatar; disconnecting clears that remembered session. The photo is loaded from Google's image host for display. Sign-in uses Google's libraries on your device; the private-folder sign-in tokens are managed by Google’s libraries and the operating system. On supported Apple builds, the separate file-access grant is stored in the local Keychain and removed on sign-out; it is not included in library exports. Tokens are not written into song files or sent to the publisher.

- There is no Singbook server. Your songs travel only between your devices and your own Google account, under Google's privacy policy. The publisher cannot access your Drive data or your Google account.
- Singbook's use and transfer to any other app of information received from Google APIs will adhere to the [Google API Services User Data Policy](https://developers.google.com/terms/api-services-user-data-policy), including the Limited Use requirements. Data from Google APIs is used only to provide the sync feature you asked for: it is not used for advertising, not sold, not transferred to third parties and not read by people.
- To stop syncing, disconnect (sign out) in the app. To remove the stored cloud copy and the app's access, see section 7.

### iCloud sync (optional, supported Apple builds)

On supported iOS and macOS builds, you can choose iCloud sync instead of Google Drive sync. It uses the iCloud account already signed in on your Apple device; Singbook does not create an iCloud or Singbook account, request your iCloud email address, or receive your Apple account credentials. Sync starts only after you choose iCloud and connect. Your library remains local if you do not enable it.

Singbook stores synced song ChordPro content, setlists, and sync metadata in the app's private CloudKit database (`iCloud.org.freevia.singbook`) in your own iCloud account. CloudKit also supplies an account identifier used to access that private database; Singbook keeps only a hashed account binding and sync bookkeeping in its local app data. This identifier is not an email address. Records are private to the account and are not shared through a public database or with other users. Freevia does not operate the database or receive its contents. Apple processes and stores the data under its iCloud terms and privacy policy. Singbook does not add end-to-end encryption; cloud data is handled under Apple's CloudKit/iCloud security.

The app syncs after you connect and automatically after song additions, edits, and removals; you can also sync on demand. Concurrent edits are reconciled, with conflicting versions retained as separate copies. The account and library binding for iCloud is separate from Google Drive, so changing providers or accounts does not merge their cloud libraries automatically. Disconnecting clears the device's active iCloud sync session only; it leaves local songs and cloud records in place. To remove song or setlist content from iCloud, delete it in Singbook and sync the deletion while connected. CloudKit may retain a small deletion marker, including the record ID and name, so the deletion can propagate to other devices; the content is removed from the synced library, but the corresponding CloudKit record is not necessarily erased. Disconnecting or deleting the app alone does not remove cloud data. Manage the full Singbook CloudKit storage through your Apple Account’s iCloud storage controls where those controls are available.

## 6. Legal basis and your rights

Because the publisher does not receive or store your data, there is normally no personal data held by the publisher to access, correct or delete. Data on your device is under your control. If you are in the EEA, UK or another region with data protection rights, you may contact privacy@freevia.org with any request; the publisher will explain what, if anything, it holds. Your rights toward the third-party services in section 3 are exercised with those services.

## 7. Deleting your data

- **Local data:** delete a song or setlist in the app, clear the app's storage in Android Settings, Apps, Singbook, Storage, **Clear data**, or uninstall Singbook.
- **Android backup:** manage or delete backups in Android Settings, Google, Backup.
- **iCloud data (only if you used sync):** delete synced songs and setlists in Singbook, then connect and sync those deletions. Their content is removed from the synced library, but CloudKit may retain a small deletion marker with the record ID and name so deletion propagates to other devices. Disconnecting or deleting the app alone does not remove cloud data. Manage Singbook’s CloudKit storage through your Apple Account’s iCloud storage controls where available.
- **Google Drive data (only if you used sync):** disconnect (sign out) in the app. Remove the app's access through Google Account, Security, Your connections to third-party apps and services (myaccount.google.com/linkedapps), select Singbook, then Remove access. For the default hidden location, delete Singbook's hidden app data in Google Drive Settings > Manage apps. For a visible folder, delete the synced files or folder directly in Drive. Your local songs are not affected and stay on your device.
- **Exported files and shares:** files you have exported or sent to others are outside the app's control and must be removed by you.

On iOS, delete individual songs/setlists in the app or delete the app to remove its local data. Offloading may preserve app data. Manage device backups through Apple’s device/account settings. Removing the app does not remove exported files or cloud copies; use the provider-specific deletion steps above. Disconnecting iCloud does not delete its cloud records.

## 8. Security

Network requests use HTTPS only; Singbook refuses plain-HTTP source requests and only follows redirects within the same site. Imported and downloaded song text is parsed as data and never executed. Local data is protected by Android's or iOS's app sandbox; Singbook does not add its own encryption of the local database. No method of electronic storage is perfectly secure. If you use Google Drive sync, Google protects data in transit and at rest in Drive. If you use iCloud sync, Apple protects data in transit and at rest through CloudKit/iCloud. Singbook does not claim end-to-end encryption for either provider.

## 9. Children

Singbook is not directed to children under 13 (or the minimum age in your country) and is not designed to attract them. Freevia does not intentionally collect children’s data through a publisher-operated account or analytics service. Provider requests and integrated components can process data as described in this policy; this is not a no-collection claim about third parties. Searches are sent to third-party music sources whose content may be unsuitable for young users.

## 10. Copyright and content

Singbook does not host lyrics or chord sheets. Text appears because you ask your device to fetch it from third-party sources. Copyright owners can send content questions or removal requests to privacy@freevia.org; the publisher cannot remove text from third-party sources or from other people's devices, but will review and act on reports regarding the app, including source availability.

## 11. Changes

The publisher may update this policy when the app or its sources change. The effective date above shows the current version; material changes will be described in the app's release notes.

## 12. Contact

Freevia EOOD, privacy@freevia.org

---

## Bulgarian (Български) - кратко резюме

*Това е кратко резюме. Пълната политика на английски език е по-горе.*

- Singbook е локално ориентирано приложение: библиотеката ви се пази на устройството, а облачно копие се създава само ако изберете и свържете Google Drive или iCloud. Няма сървър на Singbook, профили, реклами или анализи. Издателят не получава библиотеката ви. Външни услуги и интегрирани компоненти могат да обработват данни съгласно пълната политика, включително при iOS.
- Когато търсите или отваряте песен, устройството ви се свързва директно (HTTPS) с външни източници (Genius, Songsterr, Ultimate Guitar, LRCLIB, YouTube Music, Lyrics.ovh/Deezer, SyncLRC, Better Lyrics, MusicBrainz, Wikidata, Wikimedia, GitHub за WorshipCommons, seanmcgrathmusic.com, filksongbook.com, Chordie). Те получават думите за търсене и IP адреса ви и имат собствени политики.
- Вход с Google за синхронизиране с Drive е по избор. По подразбиране песните и сетлистите се пазят в скритата папка на приложението (`drive.appdata`) във вашия Google Drive; в Android или macOS можете да изберете видима папка. По избор, на поддържани устройства на Apple можете да използвате iCloud: съдържанието на библиотеката и метаданните за синхронизация се пазят в личната база данни CloudKit на вашия iCloud акаунт. Singbook не получава iCloud имейла или паролата ви и издателят няма достъп до копието. Изключването запазва облачното копие; за изтриване на съдържание от iCloud изтрийте песните/сетлистите в приложението и синхронизирайте промените. Малък маркер с идентификатор и име може да остане в CloudKit, за да се разпространи изтриването; управлявайте пълното CloudKit хранилище чрез настройките за iCloud на Apple акаунта, когато са налични.
- Изтриване: изтрийте песни в приложението, "Изчистване на данните" в Настройки на Android, деинсталирайте приложението, или (при синхронизиране) изтрийте данните на приложението от Google Drive. За iCloud изтрийте съдържанието на синхронизираните песни и сетлисти в Singbook и синхронизирайте промените. Малък маркер с идентификатор и име може да остане в CloudKit за разпространение на изтриването; управлявайте пълното хранилище чрез настройките за iCloud на Apple акаунта, когато са налични.
- Приложението не е предназначено за деца под 13 г. Външните услуги могат да обработват заявки, IP адреси и служебни идентификатори според собствените си политики.
- Контакт: privacy@freevia.org

## Ukrainian (Українська) - короткий виклад

*Це короткий виклад. Повний текст політики англійською мовою наведено вище.*

- Singbook — локально орієнтований застосунок: бібліотека зберігається на пристрої, а хмарна копія створюється лише якщо ви виберете й підключите Google Drive або iCloud. Немає сервера Singbook, облікових записів, реклами чи аналітики. Видавець не отримує вашу бібліотеку. Сторонні сервіси та інтегровані компоненти можуть обробляти дані відповідно до повної політики, зокрема на iOS.
- Коли ви шукаєте або відкриваєте пісню, пристрій напряму (HTTPS) звертається до сторонніх джерел (Genius, Songsterr, Ultimate Guitar, LRCLIB, YouTube Music, Lyrics.ovh/Deezer, SyncLRC, Better Lyrics, MusicBrainz, Wikidata, Wikimedia, GitHub для WorshipCommons, seanmcgrathmusic.com, filksongbook.com, Chordie). Вони отримують пошукові слова та вашу IP-адресу й мають власні політики.
- Вхід через Google для синхронізації з Drive необов'язковий. За замовчуванням пісні та сетлисти зберігаються у прихованій папці застосунку (`drive.appdata`) у вашому Google Drive; в Android або macOS можна вибрати видиму папку. За бажанням на підтримуваних пристроях Apple можна використовувати iCloud: вміст бібліотеки та метадані синхронізації зберігаються у приватній базі CloudKit вашого облікового запису iCloud. Singbook не отримує адресу iCloud чи пароль, а видавець не має доступу до копії. Вимкнення синхронізації зберігає хмарну копію; щоб видалити вміст з iCloud, видаліть пісні/сетлисти в застосунку та синхронізуйте зміни. У CloudKit може залишитися невеликий маркер з ідентифікатором і назвою для поширення видалення; повним сховищем CloudKit можна керувати в налаштуваннях iCloud облікового запису Apple, якщо такі засоби доступні.
- Видалення: видаліть пісні в застосунку, "Очистити дані" в налаштуваннях Android, видаліть застосунок або (у разі синхронізації) видаліть дані застосунку з Google Drive. Для iCloud видаліть вміст синхронізованих пісень і сетлистів у Singbook та синхронізуйте зміни. У CloudKit може залишитися невеликий маркер з ідентифікатором і назвою для поширення видалення; повним сховищем можна керувати в налаштуваннях iCloud облікового запису Apple, якщо такі засоби доступні.
- Застосунок не призначений для дітей до 13 років. Сторонні сервіси можуть обробляти запити, IP-адреси та службові ідентифікатори за власними політиками.
- Контакт: privacy@freevia.org
