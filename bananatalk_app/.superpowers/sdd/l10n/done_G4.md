# G4 — vi (Vietnamese) & fr (French)

Note: `.superpowers/sdd/l10n/missing_vi.json` and `missing_fr.json` did not exist at
task start (only `missing_tg.json` and `missing_zh_TW.json` were present). Computed
the missing-key sets myself by diffing `lib/l10n/app_en.arb` against `app_vi.arb` /
`app_fr.arb` (non-`@` keys only), which is equivalent to what those files would have
contained.

## vi (Vietnamese)
- File: `lib/l10n/app_vi.arb`
- Keys added: 255
- All placeholders (`{name}`, `{count}`, `{total}`, `{percent}`, `{feature}`, `{language}`,
  `{reason}`, `{time}`, `{error}`, `{size}`, `{savings}`, `{date}`) preserved exactly; no
  ICU `plural`/`select` structures among the missing keys.
- `dateFormat` translated as `"DD.MM.YYYY"` (Vietnamese day-month-year convention;
  other locales use similarly localized abbreviations, e.g. fr = `JJ.MM.AAAA`).
- Verified: valid JSON, total key count 2093 → 2348 (2093 + 255), zero remaining
  missing keys vs `app_en.arb`.

## fr (French)
- File: `lib/l10n/app_fr.arb`
- Keys added: 69
- All placeholders (`{total}`, `{percent}`, `{language}`, `{name}`, `{reason}`, `{time}`,
  `{error}`) preserved exactly.
- Verified: valid JSON, total key count 2313 → 2382 (2313 + 69), zero remaining
  missing keys vs `app_en.arb`.

## Verification performed
- Confirmed translated key sets exactly match each missing-key set (no extra/missing keys).
- Regex-checked `{placeholder}` tokens match 1:1 between English source and translation
  for every added key — zero mismatches.
- `json.load()` succeeded on both edited `.arb` files post-edit.
- Did not touch any other locale file. Did not run git or `flutter gen-l10n`.
