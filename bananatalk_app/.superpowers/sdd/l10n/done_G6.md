# G6 locales done: pt, ru, ko

Note: `.superpowers/sdd/l10n/missing_pt.json`, `missing_ru.json`, `missing_ko.json` did not exist in the repo.
Generated the missing-key sets myself by diffing `lib/l10n/app_en.arb` keys against `app_pt.arb`,
`app_ru.arb`, and `app_ko.arb` (script + intermediate files kept in scratchpad, not committed to repo).

- pt (Portuguese): 114 keys added to `lib/l10n/app_pt.arb`
- ru (Russian): 114 keys added to `lib/l10n/app_ru.arb`
- ko (Korean): 98 keys added to `lib/l10n/app_ko.arb`

Verification performed:
- All three .arb files parse as valid JSON after edits.
- Added key set == full missing set per locale (no extras, none skipped).
- All `{placeholder}` tokens (`{name}`, `{count}`, `{total}`, `{percent}`, `{language}`, `{reason}`,
  `{time}`, `{error}`) preserved verbatim (regex-diffed against English source, 0 mismatches).
- No ICU `{count, plural, ...}` constructs were present among missing keys for any of the three locales.
- No existing keys were modified; only appended before the closing `}`.

Files touched: `lib/l10n/app_pt.arb`, `lib/l10n/app_ru.arb`, `lib/l10n/app_ko.arb` only.
No git commands run, no `flutter gen-l10n` run.
