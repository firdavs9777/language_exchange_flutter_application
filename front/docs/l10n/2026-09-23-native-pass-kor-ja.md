# Korean (kor.json) + Japanese (ja.json) localization review

Source of truth: `src/utils/locales/eng.json` (868 leaf strings).
Both files now have **868 keys, key-parity OK** with eng.json, 2-space indent, trailing newline.

## Counts

| File | Total keys | Rewritten | Added (were missing) | Removed (stale/extra) | Left as-is |
|---|---|---|---|---|---|
| `kor.json` | 868 | 409 | 53 | 32 | 406 |
| `ja.json` | 868 | 348 | 52 | 32 | 468 |

Both files were **out of key parity before this pass** (kor 847 keys, ja 848). Missing blocks that had
to be written from scratch in both: the whole `newChat.*` screen (17 keys), `linking.*` (5),
`communityDetailSection.suggested.*` (2), the new home pricing model (`home.pricing.monthly.*`,
`home.pricing.yearly.*`, `free.cta`, `free.features.moments`, `free.features.tutor_trial`,
`fineprint`), and the new `home.features.translate / tutor / voice_rooms / calls` cards.
Korean was additionally missing `authentication.login.signInWithGoogle`.
Stale keys removed in both (they no longer exist in English): `home.hero.stats.*`,
`home.features.video/lessons/voice/languages.*`, `home.pricing.mostPopular`, `home.pricing.getStarted`,
`home.pricing.free.features.connections/lessons`, `home.pricing.premium.*`, `home.pricing.lifetime.*`,
`communityDetail.suggested.*` (the English key lives under `communityDetailSection`).

Also fixed in Korean: an entire untranslated English block — all 25 strings of
`authentication.passwordReset.*` plus `authentication.enterEmail.subtitle` were still raw English.
Japanese had the same untranslated `passwordReset` block and `enterEmail.subtitle`.

---

## Korean — 15 most significant rewrites

| Key | Before | After | Why |
|---|---|---|---|
| `authentication.passwordReset.*` (25 strings) | `"Set new password"`, `"Resend code"`, … (raw English) | `새 비밀번호 설정`, `코드 다시 보내기`, … | The entire password-reset flow shipped in English to Korean users. |
| `authentication.enterEmail.subtitle` | `We'll send a verification code to your email` | `이메일로 인증 코드를 보내드릴게요` | Same: untranslated. |
| register (file-wide) | `~습니다 / ~하십시오` mix (`아직 댓글이 없습니다`, `업데이트되었습니다`) | 해요체 throughout (`아직 댓글이 없어요`, `프로필을 저장했어요`) | Brief calls for one register; 해요체 is what KakaoTalk/Instagram KR use for consumer UI. 하십시오체 kept only for the legal/SEO `privacy`/`terms` descriptions. |
| `moments_section.share.fallbackTitle`, `create.header`, `profile.stats.moments` | `모먼트` | `모멘트` | The file used two spellings of the product term; 모멘트 matches the mobile app. |
| `authentication.login.invalidCredentialsError` | `유효하지 않은 자격 증명` | `이메일 또는 비밀번호가 올바르지 않아요` | `자격 증명` is a machine rendering of "credentials"; nobody says this in a consumer app. |
| `home.hero.chatPreview.*` | `안녕하세요! 잘 지내세요? 👋` / `네! 한국어 연습 중이에요!` | `Hi! 주말 어떻게 보냈어요?` / `I went hiking with friends ⛰️` / `좋아요! hiking → 등산. 학습 목록에 저장했어요.` | The preview is supposed to demonstrate cross-language chat + saved vocabulary; the old KR version was two Koreans talking, which shows nothing. |
| `home.features.*` (6 cards) | old feature set (영상 통화 / 인터랙티브 레슨 / 50개 이상 언어) | new English cards: 교정까지 되는 채팅 / 번역 기능 내장 / AI 튜터 / 보이스 룸 / 음성·영상 통화 / 진짜 커뮤니티 | Korean was still translating a previous homepage; keys no longer matched English. |
| `home.pricing.title` | `요금제 선택` | `시작은 무료, 더 빨리 배우고 싶을 땐 VIP.` | English copy changed; the old line lost the whole free→VIP message. |
| `home.download.title` / `description` | `어디서든 바나나톡과 함께` / generic app blurb | `제대로 즐기려면 모바일에서` / `AI 튜터, 보이스 룸, 통화, 실시간 알림은 앱에서만 쓸 수 있어요…` | Meaning drift (and `바나나톡` transliterated a brand that must stay `BananaTalk`). |
| `communityMain.memberCard.actions.wave` + `waves.*` | `인사하기` vs `손흔들기` (two terms) | `손 흔들기` everywhere, correct spacing | One term per concept; `손흔들기` is also a spacing error. |
| `moments_section.likedMoment` | `모멘트를 좋아합니다` | `좋아요를 눌렀어요` | Literal "Liked moment" read as a statement of affection, not a toast. |
| `communityMain.results.membersFound` | `{{count}}명의 회원 발견` | `멤버 {{count}}명` | Telegraphic "발견"; also unified 회원→멤버 across the community surface. |
| `profile.messages.*` (success/failure toasts) | `프로필이 성공적으로 업데이트되었습니다` | `프로필을 저장했어요` | Korean app toasts don't say "성공적으로"; passive + adverb is a translation tell. |
| `settings.items.helpCenter` | `도움말 센터` | `고객센터` | What Korean apps actually call this. |
| `consent.decline` / `notFound.title` | `괜찮습니다` / `이 페이지는 존재하지 않습니다` | `괜찮아요` / `이 페이지는 없어요` | Register + plain speech. |

### Korean terminology decisions
- Moments → **모멘트** (never 모먼트); Stories → **스토리**; community → **커뮤니티**;
  language partner → **언어 파트너**; native speaker → **원어민**; AI tutor → **AI 튜터**;
  Voice Rooms → **보이스 룸**; VIP / BananaTalk / App Store / Google Play / Pro / GIF kept verbatim.
- members → **멤버** (community surfaces), generic accounts → **사용자**; 회원 dropped except `VIP 회원`.
- wave → **손 흔들기** (noun and button), replacing the old 인사하기/손흔들기 split.
- topics → **주제** (nav, filters), **관심 주제** in the profile section where it means the user's interests.
- nearby → **근처**; username → **사용자 이름** everywhere (including the new `newChat` hints).
- Ellipsis normalised to `…`; loading/progress strings keep it, search placeholders drop it
  (`대화 검색`, not `대화 검색...`) the way Korean apps write placeholders.

---

## Japanese — 15 most significant rewrites

| Key | Before | After | Why |
|---|---|---|---|
| `authentication.passwordReset.*` (25 strings) | raw English | `新しいパスワードを設定`, `コードを再送信`, … | Whole flow was untranslated. |
| `authentication.enterEmail.subtitle` | `We'll send a verification code to your email` | `メールアドレス宛に認証コードをお送りします` | Untranslated. |
| `home.hero.chatPreview.message2` | `Hey! I'm practicing Japanese!` | `주말에 친구들과 등산 갔어요 ⛰️` (with `안녕하세요！週末はどうでしたか？` and `いいですね！산 → 山。学習リストに保存しました。`) | The preview must show a foreign-language message being translated; an English line to a JA audience demonstrated nothing. |
| `communityMain.languageChip.fluent` | `ネイティブ` | `流暢` | Mistranslation: FLUENT and NATIVE are different chips and both read ネイティブ. |
| `image_upload.image` / `images` / `remaining_slots` | `枚の画像を` as the word for "image" | `画像` + `{{item}}をあと{{count}}枚追加できます` | The old value only worked inside one sentence and was nonsense anywhere else. |
| `home.features.*` (6 cards) | ビデオ通話 / インタラクティブレッスン / 50以上の言語 … | 添削つきのチャット / 翻訳機能を内蔵 / AIチューター / ボイスルーム / 音声・ビデオ通話 / 本物のコミュニティ | Cards were from the previous homepage; keys didn't match English. |
| `home.pricing.*` | プレミアム / ライフタイム plans | VIP — 月額 / VIP — 年額 + `fineprint` | Pricing model changed in English (monthly/yearly VIP, auto-renew disclosure). |
| `home.download.title` / `description` | `BananaTalkをどこでも` / generic | `本領を発揮するのはアプリです` / `AIチューター、ボイスルーム、通話、リアルタイム通知はアプリ限定です。…` | English now states mobile-only features; old JA implied the web had everything. |
| `home.hero.subtitle` | 常体 (`…それが学びになる。`) | 敬体 (`…それが学びになります。`) | The one 常体 island in a です・ます file. |
| `moments_section.share.success` / `copied`, `communityMain.visitors.*`, `tandemCard.defaultTopic` | half-width `!` | full-width `！` | Typography: JA uses full-width `！？` in body copy. |
| `chatPage.deleteModal.bodyPrefix` | `次のユーザーとの会話を削除しますか:` | `次の相手との会話を削除しますか？` | 相手 is the natural word in a chat app; full-width `？`. |
| `learning.dashboard.subtitle` / `review.greatJob` | `その調子で頑張りましょう！` / `お疲れ様でした！` | `その調子です！` / `お疲れさまでした！` | Shorter, and the standard kana spelling of おつかれさま in UI copy. |
| `vip.upgradeInAppDesc` | `VIPサブスクリプションはモバイルアプリからのみ購入できます` | `VIPはモバイルアプリからのみ購入できます` | Trimmed the redundant カタカナ chain. |
| `settings.items.*Desc` | noun fragments (`個人情報を更新`) | `基本情報を更新します` etc. | Consistent 敬体 across the settings list. |
| `consent.decline` | `結構です` | `利用しない` | 結構です is ambiguous (can read as "yes, fine"); Apple/Google JA consent UIs use a plain verb. |

### Japanese terminology decisions
- Moments → **モーメント**; Stories → **ストーリー**; community → **コミュニティ**;
  language partner → **言語パートナー**; native speaker → **ネイティブスピーカー**;
  AI tutor → **AIチューター**; Voice Rooms → **ボイスルーム**; wave → **ウェーブ**;
  topics → **トピック**; nearby → **近くの人**; VIP / BananaTalk / App Store / Google Play kept verbatim.
- native language → **母語** consistently (was 母国語/母語 mixed).
- Punctuation: `。、！？（）` full-width; `…` for ellipsis; no `...`; no doubled spaces (verified by script).
- Register: です・ます throughout, no 致します; imperatives as `〜してください` / `〜しましょう`.

---

## Deliberately left alone

- `footer.allRightsReserved` in `ja.json` stays `All rights reserved.` — the standard legal formula on
  Japanese sites; translating it would change a legal string. Korean uses `모든 권리 보유.`
- `chatPage.gif.poweredBy` (`Powered by GIPHY`) — attribution required verbatim by GIPHY.
- `seo.privacy.description` / `seo.terms.description` in Korean keep 합니다체 (legal register), which is
  the one intentional exception to the 해요체 rule.
- `communityMain.results.showing` keeps `{{plural}}` even though it is meaningless in KO/JA — the key is
  currently unused in the app and the controller's parity test requires the key and its placeholders.
- Suffix/prefix-shaped keys (`communityDetailSection.about.noBioMessage`, `callToAction.title`,
  `memberInfo.yearsOld`, `accessibility.userPhoto`, `moments_section.question`,
  `chatPage.deleteModal.bodyPrefix`) are concatenated with a name in the components
  (e.g. `{prefix} <b>{name}</b>?`). I kept them grammatical as standalone fragments
  (`님은 아직 소개를 쓰지 않았어요` / `さんはまだ自己紹介を書いていません`), but the *word order* around the
  injected name is fixed by JSX and cannot be made fully natural from the locale file alone. Fixing that
  needs a component change (interpolate `{{name}}`), which is out of scope for this pass.
- `learning.*` strings that are bare counters (`장 남음`, `枚残り`, `명 참여`, `人が参加`) keep their
  fragment form because the number is rendered adjacent in the component.

## Verification run

```
node -e "JSON.parse(require('fs').readFileSync('src/utils/locales/kor.json','utf8'))"   # ok
node -e "JSON.parse(require('fs').readFileSync('src/utils/locales/ja.json','utf8'))"    # ok
parity check → kor parity OK / ja parity OK
```
Additional automated checks run over both files: placeholder sets identical to English per key
(0 mismatches), no `...`, no double spaces, no stray Latin words outside product names/placeholders,
all `seo.*.title` < 60 chars and `seo.*.description` < 160 chars.
