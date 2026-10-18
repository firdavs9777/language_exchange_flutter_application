# DE / RU / TR localization review — BananaTalk

## Why this was bigger than a wording pass
`eng.json` had drifted ahead of all three target files after the marketing-homepage rewrite
(commits `722e375`/`e670124`): 32 obsolete keys (old `home` hero/features/pricing shape,
`communityDetail.suggested` in the wrong parent) had to be removed and 52-53 new keys
(`newChat.*`, `linking.*`, `communityDetailSection.suggested.*`, new `home.*` fields, and — TR
only — `authentication.login.invalidCredentialsError`) had to be added and translated from
English, or the parity test would fail outright. On top of that, all three files had an
**entire password-reset flow (27 strings) and `enterEmail.subtitle` left untranslated in raw
English** — that's now fixed. Every fix keeps the same key/JSON structure as `eng.json`.

## Changed counts (leaf strings, out of 868 total)
| File | Added (new keys) | Changed (rewritten value) | Removed (obsolete keys) |
|---|---|---|---|
| de.json | 52 | 90 | 32 |
| ru.json | 52 | 90 | 32 |
| tr.json | 53 | 92 | 32 |

"Changed" includes ~31 per-file typographic ellipsis fixes (`...` → `…`) plus the substantive
rewrites below. Parity check: **de OK, ru OK, tr OK** (`JSON.parse` succeeds for all three,
zero missing/extra keys vs. `eng.json`).

## Structural fixes (all 3 files, identical set)
- Added `newChat.*` (17 keys) — was missing entirely.
- Added `linking.share.*`, `linking.openInApp.label`, `linking.appBanner.text` (5 keys) — missing entirely.
- Moved `suggested.{title,seeAll}` from `communityDetail` (wrong parent, now removed) to
  `communityDetailSection.suggested` (correct parent per `eng.json`).
- Rebuilt `home.hero` (dropped the stray `stats.{users,languages,countries}` sub-object that
  no longer exists in English), `home.features` (dropped `video`/`lessons`/`voice`/`languages`,
  added `translate`/`tutor`/`voice_rooms`/`calls`), and `home.pricing` (dropped `mostPopular`,
  top-level `getStarted`, the whole `premium` and `lifetime` blocks; added `fineprint`, `free.cta`,
  `free.features.{moments,tutor_trial}`, and the whole `monthly`/`yearly` blocks).
- TR only: added `authentication.login.invalidCredentialsError` (present in eng/de/ru, missing in tr).
- Translated the entire `authentication.passwordReset.*` block (27 strings) and
  `authentication.enterEmail.subtitle`, which were left as raw English in all three files —
  this was a broken flow, not a style issue.
- Normalized `...` → `…` (31 loading/placeholder strings per file).

## Register decisions
- **German**: informal "du" throughout, already the established convention — kept and extended
  it into the new passwordReset/home strings (e.g. "Wähle ein sicheres Passwort für dein Konto").
- **Russian**: informal-polite "вы/ваш", always lowercase, imperative forms preferred where
  natural (e.g. "Подтвердите пароль" rather than spelling out "вы"). Matches the file's existing
  pattern.
- **Turkish**: the app chrome (settings, auth, profile) already used formal "siz" possessive
  suffixes (`hesabınızı`, `profilinizi`) before I touched it — kept that for passwordReset/newChat.
  The marketing **home page** (hero tagline "Yanlış söyle." / "Wir übersetzen." equivalent) had
  already been written in informal "sen" imperative before my edit ("söyle", "yaz") — I extended
  that same casual register across the *rest* of the new home copy (badge, description, features,
  steps, pricing, download, cta) so the marketing surface reads as one voice, while leaving
  transactional screens in "siz". This mirrors how most Turkish consumer apps split tone between
  landing-page copy and account/settings flows.

## Terminology decisions
- Moments / Stories kept as loanwords in all three files (DE localizes the plural as "Storys",
  matching the file's pre-existing `moments_section.promo` usage; RU/TR keep "Stories" verbatim).
- AI tutor: DE "KI-Tutor", RU "ИИ-репетитор", TR "Yapay Zeka Öğretmeni" (title) / "yapay zeka
  öğretmeni" (inline) — all three already used these terms before my edit; I applied them
  consistently to the new `home.features.tutor`, `home.pricing.*` strings.
- New "Voice Rooms" feature: translated rather than borrowed, for naturalness — DE "Sprachräume",
  RU "Голосовые комнаты", TR "Sesli Odalar" — used identically in `home.features.voice_rooms`
  and `home.pricing.monthly.features.voice_rooms`.
- "study queue": DE "Lernliste", RU "список для изучения", TR "çalışma listesi" — coined once
  (new concept) and used consistently in the hero chat preview and `features.translate`.
- Community/VIP/BananaTalk/App Store/Google Play left untouched per instructions.

## Top rewrites — German
1. `home.hero.badge` "Sprachaustausch leicht gemacht" → "Sprachaustausch mit echten Menschen" — old copy no longer matches the English source ("Language exchange, real people").
2. `home.hero.titlePart1/titleHighlight/titlePart2` "Lerne Sprachen durch / Sprechen / mit Muttersprachlern" → "Übe / jede Sprache / mit jemandem, der sie wirklich spricht." — full rewrite to match the new marketing headline, not a mistranslation of the old one.
3. `home.hero.chatPreview.*` — old demo was a generic "Hallo, ich übe Deutsch" exchange; replaced with the actual Korean-learning screenshot demo from `eng.json` (Korean text kept verbatim, English glosses translated: "Wie war dein Wochenende?", "In deiner Lernliste gespeichert.").
4. `authentication.passwordReset.*` (27 keys) — was 100% untranslated English (e.g. `verifyTitle: "Enter verification code"`) → "Bestätigungscode eingeben", etc. This was a broken user-facing flow, the single highest-impact fix.
5. `home.pricing.free.features.messaging` "Einfache Nachrichten" → "Unbegrenzter 1-zu-1-Chat mit Übersetzung" — meaning changed in source (free tier is no longer "basic messaging", it's unlimited 1:1 chat).
6. `home.download.features.fast` "Schnell & leichtgewichtig" → "Kostenlose Installation" — English meaning changed from "fast & lightweight" to "free to install"; old translation would now be false.
7. `home.pricing.monthly`/`yearly` (new blocks replacing `premium`/`lifetime`) — VIP is now two billing terms, not "Premium" vs. "Lifetime"; translated the new highlight/cta/feature copy from scratch.
8. `home.cta.title` "Bereit, deine Sprachreise zu beginnen?" → "Bereit für ein echtes Gespräch?" — English CTA reoriented from "start your journey" to "have a real conversation".
9. `home.steps.partners.description` "Durchsuche unsere Community und finde perfekte Sprachaustauschpartner" → "Durchsuche die Community nach Sprache, Land oder Thema. Wink oder schreib jemandem, der dich interessiert." — old copy was generic; new copy describes actual filter/wave mechanics.
10. `communityDetail.suggested.*` → moved to `communityDetailSection.suggested.*` (same wording, correct parent) — was silently orphaned under the wrong section and would never have rendered on the actual "suggested members" surface.

## Top rewrites — Russian
1. `home.hero.badge/titlePart1/titleHighlight/titlePart2` "Языковой Обмен — Это Просто / Учите Языки / Разговаривая / с Носителями Языка" → "Языковой обмен с настоящими людьми / Практикуйте / любой язык / с тем, кто правда на нём говорит." — full rewrite to new headline; also fixed Title Case overuse (Russian doesn't capitalize every word).
2. `home.hero.chatPreview.message2` — was literally untranslated English "Hey! I'm practicing Russian!" left in the file → replaced with the real demo content "주말에 친구들과 등산 갔어요 ⛰️" (Korean, per source) plus translated glosses elsewhere in the block.
3. `authentication.passwordReset.*` (27 keys) — entirely untranslated English → fully localized ("Введите код подтверждения", "Придумайте новый пароль", etc.), same broken-flow fix as DE.
4. `home.features.title/subtitle` "Всё, Что Нужно Для Обучения" (Title Case) → "Всё, что нужно, чтобы по-настоящему заговорить на языке" (sentence case, matches new English meaning about actually speaking, not just "learning").
5. `home.pricing.title` "Выберите Свой План" → "Бесплатно для начала. VIP — когда захотите учиться быстрее." — new pricing headline emphasizes free-first, not "choose your plan".
6. `communityDetailSection.suggested.seeAll` "Посмотреть всех" → "Посмотреть всех участников" — old string (moved from the wrong parent) was ambiguous ("see all" of what); made it explicit to match "See all members".
7. `home.pricing.monthly.features.voice_rooms` (new) "Создавайте и закрепляйте голосовые комнаты" — introduces the new "Voice Rooms" feature with a natural Russian verb pair (host/pin → create/pin) rather than a clunky calque of "host".
8. `home.download.description` "Учитесь на ходу с нашим мобильным приложением..." → "ИИ-репетитор, голосовые комнаты, звонки и мгновенные уведомления доступны только в приложении..." — meaning changed from generic "learn on the go" to "these specific features are mobile-only".
9. `home.cta.description` "Присоединяйтесь к миллионам учеников и начните говорить на новом языке уже сегодня" → "Присоединяйтесь к сообществу BananaTalk и начните практиковаться уже сегодня. Банковская карта не нужна." — matches new English exactly (adds the "no credit card" reassurance that was missing).
10. `home.pricing.yearly.features.equiv` (new) "Всего 4,16 $ / месяц в среднем" — kept the exact USD figure from source (no currency conversion/claim change), phrased as a natural Russian price callout.

## Top rewrites — Turkish
1. `home.hero.titlePart1/titleHighlight/titlePart2` "Dilleri / Konuşarak / Anadil Konuşmacılarıyla Öğrenin" → "İstediğin dili / gerçekten konuşan biriyle / pratik yap." — reordered for natural Turkish SOV syntax (object → modifier → verb) instead of a word-for-word English order that read awkwardly.
2. `authentication.passwordReset.*` (27 keys) + `authentication.enterEmail.subtitle` — entirely untranslated English → fully localized in formal "siz" register ("Doğrulama kodunu girin", "Hesabınız için güçlü bir şifre seçin"), matching the file's existing account-flow tone.
3. `authentication.login.invalidCredentialsError` — key was missing from tr.json entirely (present in en/de/ru) → added "Geçersiz kimlik bilgileri".
4. `home.hero.chatPreview.message2` — untranslated English "Hey! I'm practicing Turkish!" left in file → replaced with the real Korean demo content plus translated glosses ("Hafta sonun nasıldı?", "Çalışma listene kaydedildi.").
5. `home.pricing.free.features.messaging` "Temel mesajlaşma" → "Çeviriyle sınırsız birebir sohbet" — free tier meaning changed from "basic messaging" to "unlimited 1:1 chat with translation".
6. `home.pricing.monthly`/`yearly` (new blocks replacing `premium`/`lifetime`) — translated new VIP monthly/yearly billing copy, including `equiv: "Ayda ortalama sadece 4,16 $"`.
7. `home.download.features.fast` "Hızlı ve hafif" → "Ücretsiz kurulum" — English meaning changed from "fast & lightweight" to "free to install".
8. `home.features.tutor.description` (new) "Rol yapma senaryoları, görsellerle kelime öğrenme ve telaffuz koçluğu — hepsi kendi yapay zeka çalışma partnerinle." — introduces roleplay/image-vocab/pronunciation-coaching concepts that didn't exist in the old feature set at all.
9. `home.cta.title` "Dil Yolculuğunuza Başlamaya Hazır Mısınız?" → "Gerçek bir sohbete hazır mısın?" — switched from Title Case + formal "-mısınız" to the same informal register as the rest of the (already-informal) hero, and matches the new English CTA about "a real conversation".
10. `communityDetailSection.suggested.*` — moved from the wrong parent (`communityDetail`) into the correct one, same wording kept ("{{name}} gibi diğer üyeler" / "Tüm üyeleri gör").

## Left alone
- All strings whose English source didn't change in meaning and that already read naturally
  (the large majority — 726/868 in de and ru, 723/868 in tr).
- Established loanwords already used correctly and consistently: DE "Chat", "Online"/"Offline",
  "Level", "Quiz", "Support", "Premium"; TR "Fitness", "Anime", "Premium" — these are normal,
  fully naturalized in everyday German/Turkish app UI and match the rest of each file.
- `home.hero.title/titleAccent/subtitle/trust` in all three files — already rewritten to match
  the new English hero tagline before this review; verified against `eng.json` and left as-is.
- A pre-existing, out-of-scope gap: `de.json`'s `communityMain.results.showing` doesn't carry the
  `{{plural}}` placeholder that `eng.json` has (German doesn't need a plural suffix on
  "Sprachpartner" so the omission is harmless, but flagging since it's a placeholder mismatch
  that predates this review and wasn't part of the marketing-homepage sync).
- Legal/SEO copy (`seo.*`, `notFound.*`, `consent.*`) — untouched, no meaning or length issues found.

## Files touched
- `/Users/davis/Desktop/Personal/language_exchange_web_front/src/utils/locales/de.json`
- `/Users/davis/Desktop/Personal/language_exchange_web_front/src/utils/locales/ru.json`
- `/Users/davis/Desktop/Personal/language_exchange_web_front/src/utils/locales/tr.json`
