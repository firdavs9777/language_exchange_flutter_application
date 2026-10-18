# Chinese localization review — `zho.json` (Simplified, Mainland) & `zh_TW.json` (Traditional, Taiwan)

Source of truth: `src/utils/locales/eng.json` (868 leaf strings).
Files edited: `src/utils/locales/zho.json`, `src/utils/locales/zh_TW.json`. Nothing else touched. Nothing committed.

## Result

| | zho.json | zh_TW.json |
|---|---|---|
| Leaf strings now | 868 | 868 |
| Reworded existing strings | 410 | 488 |
| Newly translated (keys that did not exist) | 62 | 62 |
| Stale keys removed (not in eng.json) | 32 | 32 |
| Left as-is | 396 | 318 |
| **Total strings changed** | **472** | **550** |

Key parity vs `eng.json`: **OK for both**. Key *order* also now matches `eng.json` exactly.
`JSON.parse` succeeds for both; 2-space indent and trailing newline preserved.

### Structural repair (both files)

Both files were **out of parity before this pass** — they carried a stale `home` tree from an
earlier homepage design and were missing three whole sections. Because a key-parity test runs
afterwards, both files were rebuilt in `eng.json` key order.

- Added: `newChat.*` (17), `linking.*` (5), `home.download.*` (10), `home.pricing.monthly/yearly/fineprint/free.cta/free.features.moments/free.features.tutor_trial` (21),
  `home.features.translate|tutor|voice_rooms|calls` (8), `communityDetailSection.suggested.*` (2).
- Removed (not in eng.json): `home.hero.stats.*`, `home.features.video|lessons|voice|languages`,
  `home.pricing.mostPopular|getStarted|premium.*|lifetime.*|free.features.connections|free.features.lessons`,
  and `communityDetail.suggested.*` (it lives under `communityDetailSection` in eng.json).

---

## zho.json — 15 most significant rewrites

| Key | Before | After | Why |
|---|---|---|---|
| `authentication.passwordReset.*` (26 strings) | `"Back to login"`, `"Enter verification code"`, `"Set new password"`, … — raw English | 返回登录 / 输入验证码 / 设置新密码 … | The entire password-reset flow shipped untranslated. |
| `authentication.enterEmail.subtitle` | `"We'll send a verification code to your email"` | 我们会把验证码发送到你的邮箱 | Same: untranslated. |
| `home.features.*` (12 strings) | 视频通话 / 互动课程 / 50+种语言 … | 边聊边纠错 / 内置翻译 / AI 导师 / 语音房 / 语音和视频通话 / 真实社区 | The whole feature block described a product that no longer matches eng.json. |
| `home.pricing.*` (21 strings) | 高级版 / 终身版 / 每日5个新连接 | VIP 月付、VIP 年付、真实权益文案 + `fineprint` 自动续期说明 | Same: stale tier structure; the yearly/monthly VIP copy is new. |
| `home.pricing.free.f3` | 发布 Moments、阅读 Stories | 发布动态、查看限时动态 | Product nouns were left in English mid-sentence. |
| `home.hero.trust` | 永久免费套餐・137种语言・AI 导师全天候 | 永久免费版 · 137 种语言 · AI 导师 24 小时在线 | `・` is the Japanese middle dot; no spacing around numerals. |
| `footer.aboutDescription` | BananaTalk致力于帮助您掌握新语言，与世界各地的母语者建立联系。 | BananaTalk 致力于帮你掌握新语言，认识世界各地的母语者。 | 您→你 (app voice); "建立联系" is a calque of "connect with"; missing Latin/CJK space. |
| `seo.home.description` | …用你的语言写,对方用他们的语言阅读,AI 导师会指出差异。 | …你用自己的语言写，对方用他们的语言读，AI 导师会告诉你差别在哪。 | ASCII commas inside Chinese text (this affected **every** `seo.*.description` and three `seo.*.title`). |
| `communityMain.highlighted.highlightSelfTopic` | 突出您的资料,让更多人看到您 | 让你的资料更醒目，被更多人看到 | ASCII comma; 突出 as a verb reads machine-translated. |
| `chatPage.deleteModal.bodyPrefix` | 删除与该用户的对话: | 确定要删除与 | The component renders `{bodyPrefix} <b>{name}</b>?` — the old string produced "删除与该用户的对话: 张三?". |
| `waves.title` + 4 related | 招手 | 打招呼 | 招手 is the literal gesture; 打招呼 is what a Chinese app calls this feature. Unified across `waves.*`, `communityMain.memberCard.actions.wave`, `communityMain.cta.viewWaves`, `settings.notificationSettings.waves`. |
| `profile.visitors.title` | 资料访客 | 谁看过我 | 资料访客 is a literal calque; 谁看过我 is the standard Chinese-app label. |
| `moments_section.promo.title` | 动态现已移至 App | 动态已经搬到 App 里了 | 现已移至 is官方公告体; the English is casual. |
| `profile.labels.of` | 的 | 日 | Rendered as `${day} ${of} ${Month}, ${year}` — "15 的 March" was broken. |
| `learning.dashboard.subtitle` | 继续保持！ | 保持住，你做得很棒！ | "Keep up the great work!" — the praise was dropped. |
| `home.hero.chatPreview.*` | 你好！最近怎么样？/ 我很好，正在练习中文！/ 太棒了！我们一起练习吧 🇨🇳 | 안녕하세요！周末过得怎么样？ / 주말에 친구들과 등산 갔어요 ⛰️ / 厉害！산 → 山，已存进你的学习清单。 | The demo bubbles are supposed to *show* the translate-and-save mechanic; the old ones showed a generic greeting. |

## zh_TW.json — 15 most significant rewrites

| Key | Before | After | Why |
|---|---|---|---|
| `home.hero.chatPreview.message2` | `"Hey! I'm practicing Chinese!"` | 주말에 친구들과 등산 갔어요 ⛰️ | Raw English left in a Traditional-Chinese file; also broke the demo's point. |
| `authentication.passwordReset.*` (26 strings) | raw English | 回到登入 / 輸入驗證碼 / 設定新密碼 … | Whole flow untranslated. |
| follow verbs — `followings`, `profile.stats.following`, `communityDetail.buttons.follow/following`, `notifications.*`, `communityDetailSection.*` (≈20 strings) | 關注 / 已關注 / 取消關注 | 追蹤 / 追蹤中 / 取消追蹤 | 關注 is the Mainland verb. Taiwan apps (LINE, Threads, IG-TW) use 追蹤. |
| `profile.title` and ~25 profile strings | 資料 / 我的資料 | 個人檔案 / 我的個人檔案 | 資料 for "profile" is a Mainland-style shortening; Taiwan says 個人檔案. |
| `profile.sections.bio`, `authentication.profile.bio` | 個人簡介 | 自我介紹 | Taiwan-natural term. |
| `profile.labels.email` + all auth email strings | 郵箱 / 郵箱地址 | 電子郵件 / 信箱 | 郵箱 is Mainland-only. |
| `profile.labels.username`, `hints.username_readonly`, `newChat.*` | 使用者名稱 | 帳號名稱 | 使用者名稱 is the literal UI-string calque; 帳號名稱 is what Taiwan users say. |
| `home.hero.trust` vs `seo.*.description` | 一處 AI 家教、另一處 AI 導師 | AI 家教 everywhere | Term was split across the file. 家教 chosen as the Taiwan term. |
| `home.pricing.*` (21 strings) | 進階版 / 終身版 / 社群存取 / 每日5個新連結 | VIP 月繳 / VIP 年繳 + real benefit copy | Stale tiers; 存取 and 連結 were mistranslations of "access"/"connections". |
| `home.pricing.free.f3` | 發佈 Moments、閱讀 Stories | 發布動態、看限時動態 | Untranslated product nouns. |
| `communityDetail.buttons.videoCall`, `chatPage.features.calls`, `home.features.calls` | (my first pass used 影片通話) → | 視訊通話 | Taiwan splits the term: 影片 = video *content*, 視訊 = video *call*. |
| `communityMain.errors.generic` | 哎呀！出了點問題 | 糟糕，出了點狀況 | 哎呀 reads Mainland; 出了點狀況 is the Taiwan phrasing. |
| `seo.home.title` | BananaTalk:與母語人士免費語言交換應用程式 | BananaTalk：跟母語者免費語言交換的 App | ASCII colon; 應用 (not 應用程式) was the Mainland word for the product; 母語人士 → 母語者 (matches the rest of the file). |
| `settings.items.helpCenter` | 幫助中心 | 說明中心 | 幫助中心 is Mainland; Taiwan products say 說明中心. |
| `learning.vocabulary.*`, `dashboard.words` | 單字/詞彙 mixed | 單字 / 單字庫 throughout | 詞彙表 is Mainland-leaning; one term per concept. |
| `waves.*` + 3 related | 招手 | 打招呼 | Same reason as zho. |

---

## Terminology decisions (one term per concept, per file)

| Concept | zho | zh_TW |
|---|---|---|
| Moments | 动态 | 動態 |
| Stories | 限时动态 | 限時動態 |
| community | 社区 | 社群 |
| language partner | 语伴 | 語伴 |
| native speaker | 母语者 | 母語者 |
| wave | 打招呼 | 打招呼 |
| topics | 话题 | 話題 |
| nearby | 附近 / 附近的人 | 附近 / 附近的人 |
| AI tutor | **AI 导师** | **AI 家教** |
| AI study partner | AI 学习搭档 | AI 學習夥伴 |
| Voice Rooms | 语音房 | 語音聊天室 |
| the mobile app | **App** (下载 App、App 内) | **App** (下載 App、App 裡) |
| "app language" setting | 应用语言 | 介面語言 |
| profile | 资料 / 个人资料 | 個人檔案 |
| bio | 个人简介 | 自我介紹 |
| follow / following | 关注 / 已关注 | 追蹤 / 追蹤中 |
| message | 消息 | 訊息 |
| video (call) | 视频通话 | 視訊通話 |
| comment | 评论 | 留言 |
| like | 赞 / 点赞 | 讚 / 按讚 |
| login / logout | 登录 / 退出登录 | 登入 / 登出 |
| settings | 设置 | 設定 |
| save | 保存 | 儲存 |
| search | 搜索 | 搜尋 |
| loading | 加载 | 載入 |
| send | 发送 | 傳送 |
| file | 文件 | 檔案 |
| account | 账号 | 帳號 |
| feed | 信息流 | 動態牆 |
| study queue | 学习清单 | 學習清單 |
| BananaTalk / App Store / Google Play / VIP / AI / GIF / Pro / MBTI / K-Pop | kept verbatim | kept verbatim |

Disambiguation: in zho, `communityMain.filterSheet.apply` was changed 应用 → 确定 so that 应用 only ever
means "app/application" in that file.

## Variant fixes

- Both files were verified character-by-character against a simplified-only / traditional-only
  character set: **0 mixed-script violations** in either file. `zh_TW` is *not* a character conversion
  of `zho` — the two differ in lexis (訊息/消息, 影片/视频, 登入/登录, 設定/设置, 檔案/文件, 追蹤/关注,
  個人檔案/资料, 自我介紹/个人简介, 說明中心/帮助中心, 家教/导师, 社群/社区, 動態牆/信息流,
  電子郵件/邮箱, 帳號/账号, 單字/单词, 相片/照片, 貼圖/贴纸), in register, and in sentence shape.
- Mainland words removed from `zh_TW`: 郵箱, 關注, 視頻, 幫助中心, 應用 (as "app"), 存取, 母語人士, 詞彙表.
- Taiwan words removed from `zho`: none were present, but `home.stats["AI tutor"]` had 导师 while
  `zh_TW` had 家教 in one place and 導師 in another — both are now internally consistent.

## Punctuation & spacing

- All ASCII `,` `.` `:` `;` `!` `?` inside Chinese runs replaced with full-width equivalents. The
  `seo.*` block (16 strings per file) was the worst offender — it used ASCII commas throughout.
- `...` replaced with a single `…` everywhere (loading states, placeholders). No `...` remains.
- `・` (Japanese middle dot) in `home.hero.trust` replaced with ` · `.
- Quote convention exercised where quoting was needed: `“”` in zho (`newChat.hintUsername`),
  `「」` in zh_TW (same key).
- Spacing convention: **one space between Chinese and Latin letters / digits**, applied consistently
  within each file (`137 种语言`, `AI 导师`, `{{count}} 分钟前`, `最多 10 张图片`, `6 位验证码`, `5 MB`).
  No space between adjacent Chinese characters (verified by scan; the only hit is the intentional
  `@用户名` token, now wrapped in quotes).
- Verified no leading/trailing whitespace on any value (eng's `moments_section.error_info` has two
  leading spaces; these were not reproduced).

## Placeholders

`{{name}}`, `{{count}}`, `{{age}}`, `{{date}}`, `{{minutes}}`, `{{hours}}`, `{{days}}`, `{{item}}`
verified present and grammatical in every string that carries them (automated diff against eng.json:
0 mismatches). `{{plural}}` in `communityMain.results.showing` is intentionally dropped — Chinese has
no plural marker, and every other CJK locale in this repo that keeps it renders a stray `s`.

## Length constraints

All `seo.*.title` are 17–32 characters (limit 60); all `seo.*.description` are 34–68 characters
(limit 160). Buttons and nav labels kept to 2–6 characters (免费开始, 逛逛社区, 打招呼, 私信, 重试,
再試一次, 套用, 重設).

## Strings deliberately left alone

- `seo.appTitle`, all occurrences of **BananaTalk**, **App Store**, **Google Play**, **VIP**, **AI**,
  **GIF**, **Pro**, **MBTI**, **K-Pop**, **XP**, `$4.16`, `72%`, `20%`, `137`.
- `chatPage.gif.poweredBy` — "Powered by GIPHY" is a required brand attribution, kept verbatim.
- `home.hero.chatPreview.message2` — the Korean line is the demo payload and is identical in eng.json.
- `footer.address` (韩国首尔江南区 / 韓國首爾江南區) — a postal address, already correct in each variant.
- `greeting`, and single-word labels that were already idiomatic (音乐/音樂, 电影/電影, 旅行, 健身,
  科技, 文化, 男, 女, 取消, 删除/刪除, 重试/重試 …) — roughly 396 strings in zho and 318 in zh_TW
  needed no change.
- No claim was added or removed anywhere; the pricing, VIP and legal/SEO strings carry exactly the
  same commitments as the English. `seo.privacy/terms/support/dataDeletion` were treated as legal
  copy: meaning preserved verbatim, only grammar, punctuation and variant vocabulary adjusted.

## Verification run

```
node -e "JSON.parse(require('fs').readFileSync('src/utils/locales/zho.json','utf8'))"    # OK
node -e "JSON.parse(require('fs').readFileSync('src/utils/locales/zh_TW.json','utf8'))"  # OK
# parity
zho parity OK
zh_TW parity OK
```

Test suite was not run, per instructions.
