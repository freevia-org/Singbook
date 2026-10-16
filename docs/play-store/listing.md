# Google Play store listing: Singbook (0.2.0)

Character counts are
checked against Play limits (title 30, short description 80, full
description 4000, what's new 500).

Prepared Play graphics and the suggested alt text are in
[`assets/`](assets/README.md).

| Field | Value |
| --- | --- |
| App name | Singbook |
| Package | org.freevia.singbook |
| Default language | English (United States) `en-US`; add `bg` and `uk` translations |
| App or game | App |
| Category | Music & Audio |
| Tags (pick up to 5 from the console's list) | Choose the closest of: Music, Musical instruments, Sheet music/Lyrics-type tags, Learning tools. Play only offers a fixed list; do not pick "Music player" or "Streaming" because Singbook plays no audio. |
| Contact email | `support@freevia.org` (public, shown on the listing) |
| Website | `https://freevia.org/singbook/` |
| Privacy policy URL | `https://freevia.org/singbook/privacy/` |
| Free / paid | Free, no in-app purchases, no ads |

Optional Google Drive sync is advertised below. **Only publish these texts in a
release built with the OAuth IDs configured** (`docs/google-oauth-setup.md`)
and after the Play Console Data safety form and [privacy policy](privacy-policy.md)
have been updated and published. If the build has no OAuth
IDs, remove the sync bullets and the "what's new" sync line.

---

## English (en-US)

### Short description (<= 80)

```
Your offline songbook: lyrics, chords and setlists in portable ChordPro files.
```
(77 characters)

### Full description (<= 4000)

```
Singbook is a local-first songbook for musicians, singers and worship teams. Keep your lyrics, chords and setlists on your own device, ready on stage or at rehearsal even without a connection.

WHAT YOU CAN DO
- Search for a song and view its lyrics and chord arrangements gathered from the third-party sources you have enabled.
- Preview full arrangements and swipe between versions and choose the one you want to play from.
- Edit chords and lyrics, transpose, and follow lyrics that carry timing information (where a source supplies it).
- Build setlists, reorder songs, override key per song, and share a setlist as an OpenSong file.
- Import ChordPro, plain text, LRC, enhanced LRC and TTML files. Export every song as a single portable ChordPro (.cho) file that keeps your edits and where the text came from.
- Optional sync between your own devices with Google Drive: sign in with Google only if you want it. Your songs and setlists go to a private, hidden app folder in your own Drive that only Singbook can use (no access to your other Drive files). After you connect, Singbook syncs automatically when you add, edit or remove songs; Sync now is also available. If the same song was edited on two devices, both versions are kept as copies.
- Print or save a clean PDF of a song.
- Keep the screen on while you perform, with reader text size, themes (light, dark, system) and palettes that suit a dim stage.
- Works on phones and tablets, with the app available in 34 languages.

PRIVATE BY DESIGN
- No Singbook account, no ads, no analytics and no tracking.
- Your library is stored on your device. Singbook has no servers of its own. If you turn on Google Drive sync, your data goes only to your own Google account, never to us.
- Searches and lookups go straight from your device to the song sources you use (for example Genius, LRCLIB, MusicBrainz, Wikidata). Those services see the search terms and your IP address, as with any website. See the privacy policy for the complete list.

IMPORTANT ABOUT CONTENT
Singbook does not host or sell lyrics or chord sheets. It retrieves text on your device from third-party websites and services, which can change, block access or remove content at any time, and results vary by song. Lyrics and chords are usually protected by copyright. Fetched text is stored for your personal use with its source and attribution; you are responsible for respecting the rights of the owners when you print, share or export it. Open-licence sources (for example WorshipCommons and other Creative Commons catalogues) keep their licence and attribution with each song.

Questions or content removal requests: privacy@freevia.org
```

### What's new in 0.2.0 (<= 500)

```
- Smoother song search and source comparison
- Setlists: per-song key override and OpenSong sharing
- Optional Google Drive sync between your devices (private app folder, conflicts kept as copies)
- Improved tablet and large-text layouts
- Bulgarian and Ukrainian translations refined
- Reliability and security fixes for imports and source lookups
```

---

## Bulgarian (bg)

### Short description

```
Офлайн песнопойка: текстове, акорди и сетлисти в преносими ChordPro файлове.
```

### Full description

```
Singbook е песнопойка, която пази всичко на вашето устройство - за музиканти, певци и worship екипи. Текстовете, акордите и сетлистите са винаги под ръка на сцената или на репетиция, дори без връзка с интернет.

КАКВО МОЖЕТЕ ДА ПРАВИТЕ
- Търсете песен и разглеждайте текстове и акордни аранжименти от външните източници, които сте включили.
- Сравнявайте аранжименти един до друг и изберете този, по който ще свирите.
- Редактирайте акорди и текст, транспонирайте и следвайте текстове с времеви данни (когато източникът ги предоставя).
- Създавайте сетлисти, подреждайте песните и задавайте тоналност за всяка песен; споделяйте сетлист като OpenSong файл.
- Импортирайте ChordPro, обикновен текст, LRC, разширен LRC и TTML. Експортирайте всяка песен като един преносим ChordPro (.cho) файл, който пази вашите промени и откъде е текстът.
- По избор: синхронизиране между вашите устройства с Google Drive - влизате с Google само ако искате. Песните и сетлистите се записват в скрита папка на приложението във вашия Drive, достъпна само за Singbook (без достъп до другите ви файлове). След свързване библиотеката се синхронизира, а след това и автоматично при добавяне, редактиране или изтриване на песен. Можете също да натиснете „Синхронизирай сега“. Ако една песен е редактирана на две устройства, и двете версии се запазват като копия.
- Отпечатайте или запишете PDF на песен.
- Екранът остава включен по време на изпълнение; размер на текста, светла, тъмна и системна тема.
- Работи на телефони и таблети, а приложението е достъпно на 34 езика.

ЛИЧНИ ДАННИ
- Без профил в Singbook, без реклами, без анализи и проследяване.
- Библиотеката ви се съхранява на устройството. Singbook няма собствени сървъри. Ако включите синхронизиране с Google Drive, данните отиват само във вашия Google акаунт, никога при нас.
- Търсенията се изпращат директно от устройството към източниците, които използвате (например Genius, LRCLIB, MusicBrainz, Wikidata). Тези услуги виждат думите за търсене и IP адреса ви, както всеки уебсайт. Пълният списък е в политиката за поверителност.

ВАЖНО ЗА СЪДЪРЖАНИЕТО
Singbook не съхранява и не продава текстове или акорди. Приложението извлича текст на вашето устройство от външни сайтове и услуги, които могат да се променят, да блокират достъпа или да премахнат съдържание по всяко време; резултатите се различават за всяка песен. Текстовете и акордите обикновено са защитени с авторско право. Извлеченият текст се пази за лична употреба заедно с източника и авторството; вие отговаряте за спазването на правата на притежателите, когато печатате, споделяте или експортирате. Източниците с отворен лиценз запазват лиценза и авторството за всяка песен.

Въпроси и искания за премахване на съдържание: privacy@freevia.org
```

### What's new

```
- По-плавно търсене и сравнение на източници
- Сетлисти: тоналност за всяка песен и споделяне в OpenSong
- По избор синхронизиране с Google Drive между устройствата (скрита папка на приложението, конфликтите се пазят като копия)
- По-добри оформления за таблети и едър текст
- Подобрени български и украински преводи
- Поправки за надеждност и сигурност при импортиране и търсене
```

---

## Ukrainian (uk)

### Short description

```
Офлайн-співаник: тексти, акорди та сетлисти в портативних файлах ChordPro.
```

### Full description

```
Singbook - це співаник, що зберігає все на вашому пристрої, для музикантів, співаків і команд прославлення. Тексти, акорди та сетлисти завжди під рукою на сцені чи репетиції, навіть без інтернету.

ЩО МОЖНА РОБИТИ
- Шукайте пісню та переглядайте тексти й акордні аранжування із сторонніх джерел, які ви ввімкнули.
- Порівнюйте аранжування поруч і обирайте те, за яким гратимете.
- Редагуйте акорди й текст, транспонуйте та стежте за текстами з часовими мітками (якщо джерело їх надає).
- Створюйте сетлисти, змінюйте порядок пісень, задавайте тональність для кожної пісні; діліться сетлистом у форматі OpenSong.
- Імпортуйте ChordPro, простий текст, LRC, розширений LRC і TTML. Експортуйте кожну пісню одним портативним файлом ChordPro (.cho), який зберігає ваші правки та походження тексту.
- За бажанням: синхронізація між вашими пристроями через Google Drive - входьте через Google, лише якщо хочете. Пісні та сетлисти зберігаються в прихованій папці застосунку у вашому Drive, доступній лише Singbook (без доступу до інших ваших файлів). Після підключення бібліотека синхронізується, а потім автоматично після додавання, редагування або видалення пісні. Також можна натиснути «Синхронізувати зараз». Якщо пісню відредагували на двох пристроях, обидві версії зберігаються як копії.
- Друкуйте або зберігайте PDF пісні.
- Екран лишається ввімкненим під час виступу; розмір тексту, світла, темна та системна теми.
- Працює на телефонах і планшетах; застосунок доступний 34 мовами.

ПРИВАТНІСТЬ
- Без облікового запису Singbook, без реклами, аналітики та стеження.
- Ваша бібліотека зберігається на пристрої. У Singbook немає власних серверів. Якщо ввімкнути синхронізацію через Google Drive, дані потрапляють лише до вашого облікового запису Google, ніколи до нас.
- Пошукові запити надходять безпосередньо з пристрою до джерел, якими ви користуєтеся (наприклад, Genius, LRCLIB, MusicBrainz, Wikidata). Ці сервіси бачать пошукові слова та вашу IP-адресу, як і будь-який вебсайт. Повний перелік - у політиці конфіденційності.

ВАЖЛИВО ПРО ВМІСТ
Singbook не розміщує і не продає тексти чи акорди. Застосунок отримує текст на вашому пристрої зі сторонніх сайтів і сервісів, які можуть змінитися, заблокувати доступ або видалити вміст у будь-який момент; результати залежать від пісні. Тексти й акорди зазвичай захищені авторським правом. Отриманий текст зберігається для особистого користування разом із джерелом та атрибуцією; ви відповідаєте за дотримання прав власників, коли друкуєте, поширюєте чи експортуєте його. Джерела з відкритою ліцензією зберігають ліцензію та атрибуцію для кожної пісні.

Питання та запити на видалення вмісту: privacy@freevia.org
```

### What's new

```
- Плавніший пошук і порівняння джерел
- Сетлисти: тональність для кожної пісні та обмін у форматі OpenSong
- Необов'язкова синхронізація через Google Drive між пристроями (прихована папка застосунку, конфлікти зберігаються як копії)
- Кращі макети для планшетів і великого тексту
- Покращені переклади болгарською та українською
- Виправлення надійності й безпеки під час імпорту та пошуку
```

---

## Claims that must stay true

- "Keep the screen on" requires the player's wakelock (`wakelock_plus`) to be
  active while a song is open; re-check before each release.
- The complete-library backup/restore ZIP (`FileActions.shareBackup`) is
  deliberately **not** advertised: it has no UI entry point. Re-add the bullet
  (and a "what's new" line) only once Settings exposes it.
- "34 languages" matches the `lib/l10n/app_*.arb` catalogs and the Android
  `localeFilters` / `locales_config.xml`; the store listing itself is only
  translated into en/bg/uk. Irish and Maltese plurals still need native review.

## Release-notes caveat

The "what's new" lines summarise the 0.2.0 work visible in the repository
history (review fixes across data, sync, providers and UI). Edit them to match
what actually ships before submitting.
