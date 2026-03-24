# Add Localization

Add new translatable strings to the BananaTalk app.

## Instructions

When adding new localization keys:

1. **Primary file:** Add the key and English value to `lib/l10n/app_en.arb` first
2. **All languages:** Add the key to ALL 18 ARB files in `lib/l10n/`:
   - `app_en.arb`, `app_es.arb`, `app_fr.arb`, `app_de.arb`, `app_pt.arb`
   - `app_ru.arb`, `app_it.arb`, `app_zh.arb`, `app_zh_TW.arb`, `app_ja.arb`
   - `app_ko.arb`, `app_hi.arb`, `app_id.arb`, `app_th.arb`, `app_tl.arb`
   - `app_tr.arb`, `app_vi.arb`, `app_ar.arb`
3. **Placeholders:** Use `{paramName}` syntax with `@key` metadata for parameterized strings
4. **Usage:** Access via `AppLocalizations.of(context)!.keyName`

## ARB Key Format

Simple string:
```json
"welcomeMessage": "Welcome to BananaTalk"
```

With placeholder:
```json
"translatedFrom": "Translated from {language}",
"@translatedFrom": {
  "placeholders": {
    "language": { "type": "String" }
  }
}
```

## Workflow
1. Add keys to all ARB files (English values as fallback for non-English files, translate if possible)
2. Run `flutter gen-l10n` to regenerate `app_localizations*.dart` files
3. Use in widgets: `final l10n = AppLocalizations.of(context)!;` then `l10n.keyName`

## Checklist
- [ ] Key added to ALL 18 ARB files
- [ ] `@key` metadata added for parameterized strings in `app_en.arb`
- [ ] `flutter gen-l10n` run successfully
- [ ] Key used in widget via `AppLocalizations.of(context)!`
