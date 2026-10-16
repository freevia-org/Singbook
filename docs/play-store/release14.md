# Release 14

Version 0.2.0+14 includes the profile photo header update, explicit YouTube Music
consent and recoverable WebView failures, local backup and restore, safer
import/sync boundaries, rich copying, source comparison and accessible navigation.

## Compatibility

The Android application ID remains org.freevia.singbook. Existing database names
and x_verse ChordPro payloads remain compatible. Database schema 4 adds local
storage for complete backup-only extension data. Cloud songs remain single
ChordPro files; synchronization stops before mutation if a local extension
cannot be represented safely. Automatic sync after song changes is retained.

Preserve saved app-access settings, the five existing internal testers and the
production selection of 178 regions. Never uninstall existing physical-device
installations to work around a signature mismatch; update through the matching
signer or Google Play instead. Legacy org.freevia.verse libraries stay intact.

## Validation

The source owner reports 1,182 automated tests passing, clean whole-project
analysis and no localization generation drift. Final native journey and signed
release artifact results must be recorded before distribution.

## Play release notes

```text
<en-US>
Recover from YouTube Music WebView failures and open consent only when requested. Add local backup and restore, safer imports and sync, richer copying and PDF export, clearer source comparison, and improved large-text navigation.
</en-US>
<bg>
Възстановяване при срив на YouTube Music и отваряне на съгласието само по ваше желание. Локални резервни копия и възстановяване, по-надеждни импортиране и синхронизация, подобрено копиране и PDF, по-ясно сравнение на източниците и навигация с голям шрифт.
</bg>
<uk>
Відновлення після збоїв YouTube Music і відкриття згоди лише на ваш запит. Локальні резервні копії та відновлення, надійніші імпорт і синхронізація, поліпшені копіювання та PDF, зрозуміліше порівняння джерел і навігація зі збільшеним шрифтом.
</uk>
```
