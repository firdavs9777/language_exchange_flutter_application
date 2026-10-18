# Romance-language locale review — es / pt / it / fr

## Scope found
All four files were stale against the current `eng.json` (868 leaf strings): each was missing 52 keys that belong to the new marketing homepage (`home.hero`, `home.features.translate/tutor/voice_rooms/calls`, `home.pricing.monthly/yearly/fineprint`, the moved `communityDetailSection.suggested`, the whole `linking.*` and `newChat.*` sections) and carried 32 obsolete keys from the pre-redesign homepage (`home.hero.stats`, `home.features.video/voice/lessons/languages`, `home.pricing.premium/lifetime`, `communityDetail.suggested`). All four also had `authentication.enterEmail.subtitle` and the entire `authentication.passwordReset` block (24 keys) left untranslated in English.

## Changed counts per file (leaf strings, vs. HEAD)
| File | Added (new keys) | Removed (obsolete keys) | Value changed | Unchanged | Total |
|---|---|---|---|---|---|
| es.json | 52 | 32 | 75 | 741 | 868 |
| pt.json | 52 | 32 | 75 | 741 | 868 |
| it.json | 52 | 32 | 74 | 742 | 868 |
| fr.json | 52 | 32 | 77 | 739 | 868 |

## Parity
`node` key-parity check: **es OK, pt OK, it OK, fr OK** (868/868 keys match `eng.json` exactly, same nesting). All four files parse as valid JSON.

## Register / terminology decisions
- **es**: neutral Latin-American Spanish, "tú" throughout (already consistent; verified no stray "usted"). "Moments"/"Stories" → translated consistently as "Momentos"/"Historias" everywhere (fixed two spots in pricing that had leaked the English words).
- **pt**: Brazilian "você" throughout (verified, no stray "tu/teu/tua"). "Moments" → translated "Momentos"; "Stories" kept as the English loanword "Stories" everywhere, matching how the file already used it (Brazilian Portuguese commonly keeps "Stories" for the Instagram-style feature) — fixed one spot in pricing that had untranslated "Moments".
- **it**: informal "tu" throughout (verified, no "Lei"). "Moments"/"Stories" → translated "Momenti"/"Storie" consistently (pricing bullet leaked both English words, fixed).
- **fr**: "vous" throughout. Found and fixed the one real register violation in the file: the old hero tagline ("Dis-le mal." / "Écris dans ta langue...") was in "tu"-form while the rest of the app is "vous" — rewritten as "Dites-le mal." / "Écrivez dans votre langue...". Kept "Moments"/"Stories" capitalized as English loanwords in marketing copy, consistent with how the rest of `fr.json` already treats them as feature names (vs. lowercase "moment"/"story" as a generic post).

## What was rewritten (new marketing homepage content, all 4 languages)
Since `eng.json`'s `home.*` was redone for the new marketing homepage, the old translations no longer matched the English meaning even though most **keys** lined up. Rewrote natively (not word-for-word) for all four languages: `home.hero` (badge, title/highlight/part2, description, getStarted, browseCommunity, lovedBy, chatPreview — kept the Korean demo lines verbatim, translated only the English annotations), `home.features` (chat/community updated, translate/tutor/voice_rooms/calls added), `home.howItWorks`, `home.steps` (profile/partners/learn), `home.pricing` (title/subtitle/fineprint/free/monthly/yearly/best/getVip — full restructure from the old free/premium/lifetime plans to free/monthly/yearly), `home.download` (title/description/features), `home.cta` (title/description/button). Added `linking.*` and `newChat.*` from scratch (no prior translation existed).

## 10 most significant rewrites — Spanish (es.json)
1. `authentication.passwordReset.*` (24 keys) → before: **entirely in English** ("Back to login", "Enter verification code"...) → after: fully translated ("Volver al inicio de sesión", "Ingresa el código de verificación"...). Why: untranslated fallback text was shipping to Spanish users.
2. `home.hero.title/titleAccent/subtitle` → before (stale, pre-redesign copy): "Dilo mal." / "Nosotros traducimos." (kept, still matched new English) but `titlePart1/titleHighlight/titlePart2/description/chatPreview` were the *old* homepage's copy ("Aprende Idiomas" / "Hablando" / "con Hablantes Nativos") → after: rewritten to match the new English ("Practica" / "cualquier idioma" / "con alguien que de verdad lo habla."). Why: content no longer matched the source at all.
3. `home.pricing.*` → before: Free/Premium/Lifetime plan structure (doesn't exist in English anymore) → after: Free/Monthly/Yearly structure with real copy ("VIP — Mensual", "Ahorra 72%", etc.). Why: whole pricing model changed.
4. `chatPage.deleteModal.bodyPrefix` → before: `"¿Eliminar tu conversación con:"` (stray colon before an interpolated `<strong>{name}</strong>?`, reads as "Delete your conversation with: Name?") → after: `"¿Eliminar tu conversación con"` (renders naturally as "¿Eliminar tu conversación con Name?"). Why: fixed a real punctuation bug, confirmed by checking `UsersList.tsx`.
5. `communityMain.results.showing` → before: `"Mostrando {{count}} compañero{{plural}} de idiomas increíble{{plural}}"` (works, but double placeholder use) → after: `"...increíbles"` fixed plural, still preserves `{{count}}`/`{{plural}}`. Minor cleanup.
6. `profile.messages.no_bio` → before: `"No se ha proporcionado información biográfica"` (stiff/legal register) → after: `"Todavía no hay información de biografía"` (conversational, Duolingo-register).
7. `linking.*` (new) → "Compartir" / "Abrir en la app" / "Abre esto en la app de BananaTalk" — added from nothing.
8. `newChat.*` (new, 17 keys) → e.g. `searchPlaceholder`: "Busca por nombre, @usuario o ID de usuario..." — added from nothing.
9. `home.pricing.free.f3` / `.features.moments` → before: `"Publica Moments y lee Stories"` (English words left in) → after: `"Publica Momentos y lee Historias"`. Why: terminology consistency with the rest of the file.
10. `seo.home.title` / `.description`, `seo.download.description` → shortened to fit the 60/160-char limits (title was 62, download description was 167) while keeping the same claims.

## 10 most significant rewrites — Portuguese (pt.json)
1. `authentication.passwordReset.*` (24 keys) → same English-leftover bug as es, fully translated to Brazilian Portuguese ("Voltar para o login", "Digite o código de verificação"...).
2. `home.hero.*` → old copy ("Aprenda Idiomas" / "Falando" / "com Falantes Nativos") replaced to match new English ("Pratique" / "qualquer idioma" / "com alguém que realmente fala.").
3. `home.pricing.*` → Free/Premium/Vitalício → Free/Mensal/Anual, full new copy.
4. `home.pricing.free.f3` → before: `"Publique Moments e leia Stories"` → after: `"Publique Momentos e leia Stories"` (translate "Moments", keep "Stories" as the established Brazilian-Portuguese loanword — matches how `promo.perks.stories.title` already uses "Stories").
5. `chatPage.deleteModal.bodyPrefix` → dropped a stray trailing colon before the interpolated name ("Excluir sua conversa com:" → "Excluir sua conversa com"), confirmed against `UsersList.tsx`.
6. `profile.messages.no_bio` → "Nenhuma informação de bio fornecida" (stiff) → "Ainda não há informações na bio" (natural).
7. `communityMain.results.showing` → fixed the broken "incrível(is)" slash/parenthetical plural notation to "incríveis".
8. `communityDetail.suggested` moved to `communityDetailSection.suggested` (the component actually renders the latter key; the old key was dead code).
9. `linking.*` / `newChat.*` (new, 20 keys total) → added, e.g. `newChat.searchPlaceholder`: "Busque por nome, @usuário ou ID do usuário...".
10. `seo.download.description` → trimmed from 161 to 148 characters to fit the limit, same meaning kept.

## 10 most significant rewrites — Italian (it.json)
1. `authentication.passwordReset.*` (24 keys) → English leftovers fully translated ("Torna al login", "Inserisci il codice di verifica"...).
2. `home.hero.*` → old ("Impara le Lingue" / "Parlando" / "con Madrelingua") → new ("Pratica" / "qualsiasi lingua" / "con qualcuno che la parla davvero.").
3. `home.pricing.*` → Gratuito/Premium/A Vita → Gratuito/Mensile/Annuale, full new copy including `fineprint`, `monthly.highlight` "Il più flessibile", `yearly.highlight` "Risparmia il 72%".
4. `home.pricing.free.f3` → before: `"Pubblica Moments e leggi le Stories"` (both English) → after: `"Pubblica Momenti e leggi le Storie"` (both translated, matching the rest of the file where "Momenti"/"Storie" are already the established terms).
5. `communityMain.results.showing` → before: `"Mostra {{count}} fantastico/i partner linguistico/i{{plural}}"` (literal, broken slash notation, unnatural) → after: `"Mostra {{count}} fantastici partner linguistici"`.
6. `chatPage.deleteModal.bodyPrefix` → dropped stray trailing colon ("con:" → "con"), confirmed against code.
7. `profile.messages.no_bio` → "Nessuna biografia fornita" → "Ancora nessuna biografia" (more casual/native).
8. `communityDetail.suggested` moved to `communityDetailSection.suggested` (the actually-used key).
9. `linking.*` / `newChat.*` (new) → e.g. `newChat.hintUsername`: "Scrivi @username per cercare per nome utente".
10. `seo.home.title` → shortened from 63 to 54 characters ("BananaTalk: app gratuita di scambio linguistico con madrelingua" → "BananaTalk: scambio linguistico gratis con madrelingua").

## 10 most significant rewrites — French (fr.json)
1. `home.hero.title/titleAccent/subtitle` → before: **"tu"-form**, the one real register break in the file ("Dis-le mal." / "Écris dans ta langue, l'autre le lit dans la sienne. Touche un message...") → after: "vous"-form ("Dites-le mal." / "Écrivez dans votre langue, l'autre personne le lit dans la sienne. Appuyez sur un message..."). Why: every other string in `fr.json` addresses the user as "vous"; this was the outlier.
2. `authentication.passwordReset.*` (24 keys) → English leftovers fully translated ("Retour à la connexion", "Entrez le code de vérification"...).
3. `home.hero.badge/titlePart1/titleHighlight/titlePart2/description/chatPreview` → old homepage copy replaced to match new English source ("Pratiquez" / "n'importe quelle langue" / "avec quelqu'un qui la parle vraiment.").
4. `home.pricing.*` → Gratuit/Premium/À vie → Gratuit/Mensuel/Annuel, full new copy (`fineprint`, `monthly.highlight` "Le plus flexible", `yearly.highlight` "Économisez 72 %").
5. `chatPage.deleteModal.bodyPrefix` → before: `"Supprimer votre conversation avec :"` (French-spaced colon before the interpolated `<strong>{name}</strong>?`) → after: `"Supprimer votre conversation avec"`, confirmed against `UsersList.tsx` so it now reads "Supprimer votre conversation avec Name ?" cleanly.
6. `communityMain.results.showing` → cleaned up the "(s)"/parenthetical plural hack to a plain plural phrasing.
7. `communityDetail.suggested` moved to `communityDetailSection.suggested` (actually-rendered key).
8. `linking.*` / `newChat.*` (new, 20 keys) → e.g. `newChat.searchPlaceholder`: "Rechercher par nom, @pseudo ou ID utilisateur...".
9. `seo.home.title/description`, `seo.download.description`, `seo.moments.description` → all four were over the 60/160-char budgets (up to 178 chars); shortened while keeping the same claims.
10. `profile.messages.no_bio` → "Aucune information de biographie fournie" (stiff/formal) → "Aucune biographie renseignée pour le moment" (more natural).

## Left alone (deliberately)
- `communityDetailSection.accessibility.userPhoto` (and es/pt/it/fr equivalents) — an awkward suffix-concatenation accessibility string (`name + t('userPhoto')`); the natural Romance-language word order would be prefix ("Photo de {name}"), which the current code structure doesn't support. Fixing the grammar would require a code change outside this task's scope (locale files only), so left as-is in all four files.
- `home.sections.features` short nav-pill labels ("Características" / "Recursos" / "Funzionalità" / "Fonctionnalités") — technically a looser match for the new English "What's inside" than for the old "Features", but they're short, natural, and already idiomatic section-nav labels; changing them for a literal match wasn't worth the churn.
- The literal `"..."` (three ASCII dots) used for loading/progress states ("Cargando...", "Enviando...", "Verifica in corso...") — `eng.json` itself uses literal `...` (32 times) rather than `…`, so this was kept consistent with the source rather than "corrected" to the Unicode ellipsis, to avoid introducing an inconsistency with the English convention the rest of the app follows.
- `communityDetail.suggested`/`communityDetailSection.callToAction`/similar dead keys that aren't referenced by any component (verified via grep) got the minimum viable fix (moved/kept parity-correct) rather than a deep rewrite, since no user ever sees them.
- The bulk of the ~740 unchanged strings per file (settings, vip, waves, topics, nearby, learning, image_upload, profile, community cards, chat, moments flows, legal-page SEO snippets not over budget) were already natural, register-consistent, and terminology-consistent on review, so left untouched.
