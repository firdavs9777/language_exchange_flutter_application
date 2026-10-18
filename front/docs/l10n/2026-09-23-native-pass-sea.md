# Localization review — ar, hi, id, th, tl, vi

## Headline finding
All six locale files were structurally out of sync with the current `eng.json` (from the recent marketing-homepage rewrite), not just stylistically stale:
- Missing the entire `newChat` section (17 keys) and `linking` section (5 keys).
- `communityDetailSection.suggested` was missing while a duplicate `communityDetail.suggested` existed instead (moved/renamed).
- `home.hero` carried a stray `stats` sub-object that no longer exists in the source.
- `home.features` still had the old `video`/`lessons`/`voice`/`languages` cards instead of the new `translate`/`tutor`/`voice_rooms`/`calls` cards.
- `home.pricing` still used the old `premium`/`lifetime` plan shape instead of `monthly`/`yearly`, and was missing `fineprint`, `free.cta`, `free.features.moments`, `free.features.tutor_trial`.
- `authentication.enterEmail.subtitle` and nearly all of `authentication.passwordReset` (26 of 27 strings) were left as literal, un-translated English in every one of the six files.
- `tl.json` was also missing `authentication.login.invalidCredentialsError` entirely.

All of this was fixed for all six languages: keys added/renamed/removed to match `eng.json` exactly, and all new/previously-English strings were translated. `home.*` content (hero, features, how-it-works/steps, pricing, download, cta) was rewritten to match the new marketing copy's actual meaning, not just patched for key parity — the old copy was a different marketing angle ("Learn languages by speaking," generic 3-step/plan cards) than the new one ("Practice any language with someone who actually speaks it," VIP monthly/yearly, mobile-only feature list).

## Changed/added strings per file
Approximate counts (structural additions + rewritten `home.*` content + translated `passwordReset`/`enterEmail.subtitle`):
- **ar.json**: ~121 strings (17 newChat + 5 linking + 2 suggested + 1 enterEmail.subtitle + 26 passwordReset + ~70 in `home.*`)
- **hi.json**: ~121 strings (same breakdown)
- **id.json**: ~121 strings (same breakdown; also re-registered several `home.*`/marketing strings from "Anda" to "kamu" for register consistency)
- **th.json**: ~121 strings (same breakdown)
- **tl.json**: ~122 strings (same breakdown + 1 for the missing `invalidCredentialsError`)
- **vi.json**: ~121 strings (same breakdown)

All six: valid JSON, 2-space indent preserved, trailing newline preserved, and **parity: OK** for all six against `eng.json` (script output below).

```
ar parity OK
hi parity OK
id parity OK
th parity OK
tl parity OK
vi parity OK
```

## 8 most significant rewrites per language

### Arabic (ar)
1. `home.hero.badge` — "تبادل لغوي بكل بساطة" (Language exchange, made simple) → "تبادل لغوي، أشخاص حقيقيون" (Language exchange, real people) — matches the new source copy's actual claim instead of the old tagline.
2. `home.hero.chatPreview.message3` — old demo was a generic "Excellent! Let's practice together 🇸🇦" → "رائع! 산 ← جبل. تم الحفظ في قائمة دراستك." — now demonstrates the actual tap-to-translate/study-queue feature the source shows, with the vocab word translated into Arabic instead of a throwaway line.
3. `home.pricing.monthly`/`yearly` — the whole `premium`/`lifetime` plan block was renamed and rebuilt (`highlight`, `cta`, all four `features.*` per tier) since the pricing model itself changed (monthly/yearly subscription, not premium/lifetime purchase).
4. `home.features.tutor`/`voice_rooms`/`calls`/`translate` — four feature cards added from scratch (previously `video`/`lessons`/`voice`/`languages`, which don't exist in the source anymore).
5. `authentication.passwordReset.*` — 26 of 27 strings were literal English ("Enter verification code", "Resend code", …); fully translated to Arabic.
6. `newChat.*` — added the entire "start a new chat" flow (17 strings) that didn't exist at all.
7. `home.download.description` — old text was generic "learn on the go, available on iOS/Android with push+offline" → new text correctly says AI Tutor/Voice Rooms/calls/live notifications are mobile-only.
8. `home.cta.title` — "هل أنت مستعد لبدء رحلتك اللغوية؟" (Ready to start your language journey?) → "مستعد لخوض محادثة حقيقية؟" (Ready to have a real conversation?) — matches the new, more conversational CTA.

### Hindi (hi)
1. `home.hero.titlePart1/titleHighlight/titlePart2` — restructured from "भाषाएँ सीखें / बोलकर / मूल भाषी लोगों के साथ" (Learn languages / by speaking / with native speakers) to "अभ्यास करें / किसी भी भाषा का / किसी ऐसे व्यक्ति के साथ जो उसे सच में बोलता है।" (Practice / any language / with someone who actually speaks it) to match the new headline's actual claim.
2. `home.pricing.title/subtitle` — "अपना प्लान चुनें" (Choose your plan) → "शुरू करना मुफ़्त। तेज़ी से सीखने के लिए तैयार होने पर VIP।" (Free to start. VIP when ready to learn faster.) plus a new `fineprint` disclosure about auto-renewal that didn't exist before.
3. `home.pricing.monthly`/`yearly` — same premium→monthly/lifetime→yearly restructure as other languages, all feature bullets rewritten.
4. `authentication.passwordReset.*` — fully translated from English placeholders.
5. `newChat.*` and `linking.*` — added wholesale (22 strings).
6. `home.features.tutor.description` — new AI Tutor pitch ("Roleplay scenarios, image-based vocab, pronunciation coaching") added; old copy only had generic "interactive lessons."
7. `communityDetailSection.suggested` — added (was incorrectly sitting under `communityDetail` instead).
8. `home.download.features.fast` — "तेज़ और हल्का" (Fast and light) → "मुफ़्त इंस्टॉल" (Free to install) — matches the new source claim, not the old one.

### Indonesian (id)
1. Register consistency: the file mixed formal **Anda** (auth, profile, home) with informal **kamu** (seo, moments promo). Per the instruction to standardize on "kamu" for a friendly consumer app, all new/rewritten `home.*`, `newChat.*`, and `linking.*` content now consistently uses **kamu**, aligning with the already-kamu seo/moments copy. (Older Anda-based screens outside the prioritized surfaces were left as-is — see "left alone.")
2. `home.hero.description` — generic "Connect with millions of learners" copy replaced with "BananaTalk menghubungkanmu dengan penutur asli dari seluruh dunia..." matching the new pairing/correction-focused pitch.
3. `home.pricing.monthly`/`yearly` — full restructure from premium/lifetime, all feature bullets rewritten to match VIP subscription tiers.
4. `authentication.passwordReset.*` — fully translated (was English).
5. `newChat.*` — added (17 strings), written in "kamu" register to match the rest of the new content.
6. `home.download.title/description` — "Bawa BananaTalk ke Mana Saja" (Take BananaTalk anywhere) → "Pengalaman lengkap ada di ponsel" (The full experience lives on mobile), reflecting the new mobile-only feature framing.
7. `communityDetailSection.suggested` — added (was misplaced under `communityDetail`).
8. `home.cta.button` — "Buat Akun Gratis" → "Buat akun gratismu" — brought in line with the "kamu" register used across the rest of the rewritten copy.

### Thai (th)
1. `home.hero.titlePart1/titleHighlight/titlePart2` — "เรียนภาษาโดยการ / พูด / กับเจ้าของภาษา" (Learn languages by / speaking / with native speakers) → "ฝึกฝน / ภาษาใดก็ได้ / กับคนที่พูดภาษานั้นจริง ๆ" (Practice / any language / with someone who actually speaks it).
2. `home.pricing.monthly`/`yearly` — restructured from premium/lifetime; new `fineprint` about App Store/Google Play auto-renewal added.
3. `authentication.passwordReset.*` — fully translated (was English placeholders throughout).
4. `newChat.*`/`linking.*` — added wholesale.
5. `home.features.*` — four cards (`translate`, `tutor`, `voice_rooms`, `calls`) rewritten/added; old `video`/`lessons`/`voice`/`languages` cards removed since they don't exist in source.
6. `home.download.description` — corrected to say AI Tutor/Voice Rooms/calls/notifications are mobile-only (old copy was generic "learn on the go").
7. `communityDetailSection.suggested` — added (moved from the wrong object).
8. `home.hero.chatPreview.message3` — rewritten to actually demonstrate the tap-to-translate/study-queue mechanic ("เยี่ยม! 산 → ภูเขา บันทึกไว้ในคิวการเรียนของคุณแล้ว") instead of a generic "let's practice together" line.

### Filipino/Tagalog (tl)
1. `authentication.login.invalidCredentialsError` — this key was **entirely missing** (not just untranslated); added: "Hindi valid na kredensyal."
2. `authentication.passwordReset.*` — fully translated from English placeholders into natural Taglish ("I-verify", "Bini-verify...", "I-reset ang Password").
3. `home.hero.titlePart1/titleHighlight/titlePart2` — "Matuto ng mga Wika sa pamamagitan ng / Pagsasalita / kasama ang mga Katutubong Nagsasalita" → "Mag-practice ng / kahit anong wika / kasama ang taong talagang nagsasalita nito" (Practice / any language / with someone who actually speaks it) — natural Taglish verb-focused phrasing rather than a noun-phrase calque.
4. `home.pricing.monthly`/`yearly` — restructured from premium/lifetime, feature bullets rewritten.
5. `newChat.*`/`linking.*` — added wholesale, in the same Taglish register as the rest of the file (e.g. "I-download ang App" convention already used elsewhere).
6. `communityDetailSection.suggested` — added (moved from the wrong object).
7. `home.download.description` — rewritten to reflect the mobile-only AI Tutor/Voice Rooms/calls/notifications framing.
8. `home.cta.title` — "Handa Ka Na Bang Simulan ang Iyong Paglalakbay sa Wika?" (Ready to start your language journey?) → "Handa ka na bang magkaroon ng tunay na usapan?" (Ready to have a real conversation?) matching the new, more direct CTA.

### Vietnamese (vi)
1. `home.hero.titlePart1/titleHighlight/titlePart2` — "Học Ngôn Ngữ bằng cách / Nói Chuyện / với Người Bản Ngữ" → "Luyện tập / bất kỳ ngôn ngữ nào / với người thực sự nói ngôn ngữ đó."
2. `home.pricing.monthly`/`yearly` — restructured from premium/lifetime; `fineprint` and `free.cta`/`free.features.moments`/`tutor_trial` added.
3. `authentication.passwordReset.*` — fully translated (this file, like the others, had left it as raw English).
4. `newChat.*`/`linking.*` — added wholesale (22 strings).
5. `home.features.tutor`/`voice_rooms`/`calls`/`translate` — four feature cards rewritten/added to replace the removed `video`/`lessons`/`voice`/`languages` cards.
6. `communityDetailSection.suggested` — added (moved from the wrong object).
7. `home.hero.chatPreview.message3` — rewritten to demonstrate the actual translate/study-queue feature: "Tuyệt! 산 → núi. Đã lưu vào hàng đợi học tập của bạn."
8. `home.download.title` — "Mang BananaTalk Đi Khắp Nơi" (Take BananaTalk everywhere) → "Trải nghiệm đầy đủ chỉ có trên di động" (The full experience lives on mobile) to match the new positioning.

## Terminology decisions
- Kept **BananaTalk**, **App Store**, **Google Play**, **VIP** untranslated/literal in all six languages (per instructions and existing precedent in every file).
- **AI**: new content I wrote uses "AI" literally in feature/product names ("AI Tutor" in id/tl/vi where the source itself doesn't localize the noun phrase; "مدرّس AI" in Arabic, "AI ट्यूटर" in Hindi, "AI ติวเตอร์" in Thai), matching the instruction to keep "AI" as-is like VIP. Existing older strings elsewhere in ar/hi/th that already spell it out descriptively (e.g. ar's "مدرّس الذكاء الاصطناعي" in `moments_section.promo`) were left alone rather than mass-edited, to avoid unrelated ripple changes outside the reviewed scope.
- **Moments / Stories**: kept as literal English brand-style terms in parentheses where the existing file convention already did this (e.g. ar/hi/id/th/tl/vi `home.pricing.free.features.moments`, matching the existing `f3` strings), for one consistent term per concept per file.
- **Voice Rooms**: kept as a literal English feature name in all six languages (consistent with how "VIP", "App Store" etc. are handled) rather than inventing six different literal translations for a specific product feature.
- Indonesian **register**: standardized new/rewritten `home.*`, `newChat.*`, `linking.*` content on **kamu** (the file's `seo.*`/`moments_section.promo` content was already "kamu"; `home.*`/auth were "Anda"). This is a partial normalization — see "left alone."

## Left alone (out of scope / lower priority)
- Deep-app screens outside the prioritized list (`profile.*`, `learning.*`, `image_upload.*`, most of `authentication.*` besides the broken passwordReset/enterEmail strings, `waves`, `topics`, `nearby`) were spot-checked but not rewritten wholesale — they already read as fluent, natural translations in all six languages.
- Indonesian's Anda/kamu mixing outside the newly-rewritten `home.*`/`newChat.*`/`linking.*` content (i.e., in `authentication.*`, `profile.*`, `chatPage.*`, etc.) was not converted — that would touch hundreds of strings well outside the prioritized marketing/nav surfaces and risk of introducing regressions outweighed the benefit given the task's stated priority order.
- Tagalog's extensive use of English nouns for UI labels (Account, Profile, Password, Email Address, Video Call, Leaderboard, Help Center, Read Receipts, etc.) was left as-is — this is genuine, natural Taglish convention (per the instruction's own example, "I-download ang app"), not an error, and rewriting it would actually work against the "natural Taglish" guidance.
- No legal/long-form policy text exists in `eng.json` (privacy/terms bodies live elsewhere), so there was nothing to apply the "fix grammar only" legal-text rule to.

## Verification
- `JSON.parse` succeeds for all six files.
- Key-parity script (from the task spec) prints `parity OK` for all six languages.
- 2-space indentation and trailing newline preserved in all six files.
