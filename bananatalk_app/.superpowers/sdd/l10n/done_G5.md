# G5 l10n done — ar, hi, ja

Note: `missing_ar.json`, `missing_hi.json`, `missing_ja.json` did not exist in `.superpowers/sdd/l10n/` (only `missing_tg.json` and `missing_zh_TW.json` were present). Diffed `lib/l10n/app_en.arb` directly against `app_ar.arb`, `app_hi.arb`, `app_ja.arb` and found the same 8 missing keys as `missing_tg.json` (confirming this was the intended missing set for this batch):

- loadMoreComments
- noForYouMomentsTitle
- noForYouMomentsBody
- noFollowingMomentsTitle
- noFollowingMomentsBody
- goToCommunity
- checkOutProfile
- checkOutCommunity

None have placeholders. Added translations to end of each ARB (before closing brace), matching existing terminology in each file (community/comments/moments terms, "Bananatalk" brand left untranslated per existing convention). Verified valid JSON via `json.load` for all three files.

Files edited:
- lib/l10n/app_ar.arb
- lib/l10n/app_hi.arb
- lib/l10n/app_ja.arb
