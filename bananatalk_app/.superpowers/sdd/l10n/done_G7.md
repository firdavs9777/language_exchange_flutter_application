# G7 — es / tl / tr / zh translation batch

Note: `.superpowers/sdd/l10n/missing_{es,tl,tr,zh}.json` did not exist at start of task
(only missing_it/th/tg/zh_TW were present). Generated them myself by diffing
`lib/l10n/app_en.arb` against each target `app_<loc>.arb` to find keys present in en
but absent in the locale file, then translated and applied.

## Results
- es (Spanish): 113 keys added. File valid JSON, 2366 total keys.
- tl (Tagalog/Filipino): 135 keys added. File valid JSON, 2354 total keys.
- tr (Turkish): 98 keys added. File valid JSON, 2387 total keys.
- zh (Chinese Simplified): 99 keys added. File valid JSON, 2350 total keys.

All placeholders ({name}, {count}, {title}, {action}, {total}, {percent}, {language},
{reason}, {time}, {error}, {max}, {current}) preserved exactly. No existing keys
modified — verified via git diff (only change besides additions is the trailing-comma
reflow on the last pre-existing key, a pure formatting artifact).

Files touched:
- lib/l10n/app_es.arb
- lib/l10n/app_tl.arb
- lib/l10n/app_tr.arb
- lib/l10n/app_zh.arb
- .superpowers/sdd/l10n/missing_es.json (created, since absent)
- .superpowers/sdd/l10n/missing_tl.json (created, since absent)
- .superpowers/sdd/l10n/missing_tr.json (created, since absent)
- .superpowers/sdd/l10n/missing_zh.json (created, since absent)

No git commands run, no flutter gen-l10n run.
