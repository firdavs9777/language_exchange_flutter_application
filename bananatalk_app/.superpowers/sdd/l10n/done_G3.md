# G3 — th / it l10n fill

Note: `.superpowers/sdd/l10n/missing_th.json` and `missing_it.json` did not exist at start (only
`missing_tg.json` and `missing_zh_TW.json` were present). Generated both by diffing
`lib/l10n/app_en.arb` keys against `app_th.arb` / `app_it.arb` (same key-set-difference method
confirmed against the existing `missing_tg.json`, which matched exactly: 8/8 keys).

## th (Thai)
- Missing keys found: 255
- Translated and added to `lib/l10n/app_th.arb`
- `dateFormat` translated as "ปปปป.ดด.วว" (mirrors it.arb's existing "GG.MM.AAAA" pattern style)

## it (Italian)
- Missing keys found: 69
- Translated and added to `lib/l10n/app_it.arb`

## Verification
- Key-set equality checked: translated dict == missing dict keys, both locales, exact match.
- Placeholder preservation checked programmatically (regex `\{[a-zA-Z_]+\}`) for every key: no mismatches.
- No `{count, plural, ...}` ICU structures present in either missing set.
- Both `app_th.arb` and `app_it.arb` re-parsed as JSON after merge: valid.
- `git diff` reviewed: only additions + one trailing-comma fix on the previously-last key
  (`roomGoToRooms`) in each file; no existing values modified.
- Did not run `flutter gen-l10n` or any git command (per instructions).
