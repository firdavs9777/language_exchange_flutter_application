# G1 locales done: zh_TW, tg

Note: `.superpowers/sdd/l10n/missing_zh_TW.json` and `missing_tg.json` did not exist in the repo.
Generated the missing-key sets myself by diffing `lib/l10n/app_en.arb` keys against
`app_zh_TW.arb` and `app_tg.arb` (script + intermediate files kept in scratchpad/`.superpowers/sdd/l10n`,
not committed).

- zh_TW (Chinese Traditional): 341 keys added to `lib/l10n/app_zh_TW.arb`
  - 273 of these already had a Simplified Chinese translation in `app_zh.arb`; converted
    those to Traditional Chinese with OpenCC (`s2twp` profile: Taiwan variant + phrase dict),
    then manually reconciled ~5 terms that OpenCC got "technically Taiwanese but wrong for
    this codebase's established convention" (e.g. OpenCC's 遮蔽/檢視/許可權/瞬間 →
    corrected to this file's existing usage 封鎖/查看/權限/動態, verified by grepping
    existing `app_zh_TW.arb` entries for each term's frequency).
  - Remaining 68 keys (leaderboard/streaks/matching/quiet-hours/moments-empty-state/misc,
    not present in app_zh.arb either) translated manually into Traditional Chinese, matching
    established in-file terminology (e.g. streak → 連擊 per `learningStreak*` keys,
    partner → 夥伴 per `languagePartner`, comment → 留言, block/unblock → 封鎖/解除封鎖).
  - None left in English.

- tg (Tajik): 8 keys added to `lib/l10n/app_tg.arb`
  - All 8 translated manually (loadMoreComments, noForYouMoments title/body,
    noFollowingMoments title/body, goToCommunity, checkOutProfile, checkOutCommunity),
    matching existing tg.arb phrasing patterns (e.g. "Ба Ҳуҷраҳо гузаштан" →
    "Ба Ҷомеа гузаштан"; "Ин лаҳзаро дар Bananatalk бубинед!" →  "Ин профилро дар
    Bananatalk бубинед!").
  - None left in English.

Verification performed:
- Both .arb files parse as valid JSON after edits (`json.load` succeeds, no trailing-comma
  or quoting errors).
- Added key set == full missing set for each locale (no extras, none skipped).
- Post-edit key sets vs `app_en.arb`: tg now exactly 2243/2243 (0 missing). zh_TW now
  2252 keys total = 2243 en-matching keys (0 missing) + 9 pre-existing zh_TW-only keys
  that aren't in app_en.arb at all (e.g. failedToUploadImages, uploadingImages — present
  before my edit, untouched, not part of this task).
- No duplicate top-level keys introduced in either file (checked via
  `json.load(..., object_pairs_hook=...)` duplicate counter).
- All `{name}`, `{error}`, `{count}`, `{total}`, `{percent}`, `{language}`, `{time}`,
  `{reason}` etc. placeholders preserved verbatim; one `{count, plural, ...}` ICU
  construct existed among zh_TW's already-converted set (`aiTutorCardReviewCount`,
  `aiTutorPlanPronunciation`, `aiTutorQuotaRemaining`) — ICU structure preserved,
  only the human-language words inside translated.
- Only existing missing keys were added; no existing keys modified or duplicated.

Files touched: `lib/l10n/app_zh_TW.arb`, `lib/l10n/app_tg.arb` only. No git commands run,
no `flutter gen-l10n` run.
