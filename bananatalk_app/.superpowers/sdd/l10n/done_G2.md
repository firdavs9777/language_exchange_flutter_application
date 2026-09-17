# G2 locales done: id, de

Note: `.superpowers/sdd/l10n/missing_id.json` and `missing_de.json` did not exist in the repo.
Generated the missing-key sets myself by diffing `lib/l10n/app_en.arb` keys against `app_id.arb`
and `app_de.arb` (script + intermediate files kept in scratchpad, not committed to repo).

- id (Indonesian): 255 keys added to `lib/l10n/app_id.arb`
- de (German): 69 keys added to `lib/l10n/app_de.arb`

Verification performed:
- Both .arb files parse as valid JSON after edits.
- Added key set == full missing set (no extras, none skipped).
- All `{placeholder}` tokens preserved verbatim (regex-diffed against English source, 0 mismatches).
- No ICU `{count, plural, ...}` constructs were present among missing keys for either locale.
- Post-edit, `id` and `de` key sets now exactly equal `app_en.arb`'s key set (2243 keys each), no duplicates.
- No existing keys were modified; only appended before the closing `}`.

Files touched: `lib/l10n/app_id.arb`, `lib/l10n/app_de.arb` only. No git commands run, no `flutter gen-l10n` run.
