# Manual TODOs

Items grouped by who can do them. Time estimates are at the start of each line so you can pick what fits an available window. When you complete something, move it under **Completed** at the bottom with a date.

Three sections:

- **👤 Humans only** — needs a real person (real-device testing, dashboard config, App Store stuff, product decisions). An agent literally can't do these.
- **🛠️ Queued engineering** — an agent can do these, but they're deferred for a specific reason (waiting on a product decision, queued for a known future wave, etc.).
- **✅ Completed** — done, kept for posterity.

---

## 👤 Humans only

### Real-device testing

- [ ] **(2 hr) Full smoke test pass on iOS physical + Android physical.** Walk all 5 tutor chips (Chat, Roleplay, Story, Photo, Pronounce) end-to-end with real OpenAI calls. Specific paths for Pronounce: 5-sentence happy path / 1 deliberate mispronunciation / 1 silent recording / custom-sentence path / mid-session back-press confirm dialog / mic permission denied path. Verify `GET /tutor/me` shows `pronunciation:<word>` in `weakAreas` after Save & Close. **Also test chat voice mode + Pronounce while a Bluetooth headset is connected** — confirm audio routes through headset and audio-session transition from chat → record doesn't blow up.
  - **Code-level finding worth knowing during the BT test:** the legacy `voice_recorder_mobile.dart` configures `AVAudioSessionCategoryOptions.allowBluetooth` + `AVAudioSessionMode.spokenAudio` explicitly, but the newer `TutorVoiceService` (Step 9) and `PronunciationVoiceService` (Step 11) rely on `flutter_sound` defaults with no explicit BT options. If BT routing fails on the new chips, the fix is to mirror the legacy session config in those two services — small, two-file change.
  - **Why this matters:** AI Study is the differentiated surface. A user discovering it crashes or doesn't route their AirPods on day 1 won't try it again. No automated test covers real microphone + real OpenAI on a real device — this is the only gate.

- [ ] **(30 min) GPT-4o vision end-to-end test with the prod OpenAI key.** Take a real photo through the 📷 Photo chip on a physical device. Confirm describe + grade both work. Sub-test: a HEIC image from the iOS Photos library (HEIC handling has historically been fragile across iOS versions).
  - **Why this matters:** Vision calls cost ~$0.08 each, and we've never tested the full upload-describe-grade path against the real prod model with a real photo — only with simulator stock images and a dev key. A pricing or auth gotcha here would surface as cryptic failures for users.

### Dashboard / external config

- [ ] **(5 min) OpenAI budget alert at $100/month.** Visit https://platform.openai.com/account/limits and set a soft + hard cap.
  - **Why this matters:** Without this, a runaway prompt loop (bug, abuse, or just a bad day) could rack up real money before we notice. The hard cap is the seatbelt.

### App Store / Play Store filings

- [ ] **(2 hr) Privacy policy delta filed across all three surfaces.** The §10 disclosures in `AI_STUDY_PROCESS.md` (voice samples + photos sent to OpenAI; 30-day retention for legacy pronunciation audio; tutor memory of weak areas etc.) need to be reflected in **three places**:
  - **Hosted privacy policy at https://banatalk.com/privacy-policy** — this is the canonical user-facing doc (referenced from `lib/pages/settings/legal_screen.dart` and the VIP screens). Lives outside this repo; edit via whatever CMS/static-site backs banatalk.com.
  - **App Store Connect privacy nutrition labels** (under App Privacy → Data Collection). Categories that need an answer or update given the new disclosures: **Audio Data** (Linked to User, App Functionality + Other Purposes — processed by OpenAI Whisper); **Photos or Videos** (Linked to User, App Functionality + Other Purposes — processed by OpenAI Vision); **User Content** (Linked to User, App Functionality — chat / roleplay text sent to OpenAI). Confirm **Data Used to Track You** is still "No" — we don't track across apps with this data.
  - **Google Play Data Safety form** (Play Console → App content → Data safety). Mirror the Apple categories: Audio Data, Photos and videos, Other user-generated content. Mark each as collected, processed, and shared with OpenAI as a third-party processor.
  - **GDPR/CCPA:** OpenAI must be named as a processor (or sub-processor depending on how the privacy policy is structured). Under CCPA, processing user audio/photos via OpenAI is not a "sale" (per OpenAI's API DPA) but still requires disclosure of the category and purpose. Add this to the policy.
  - **Why this matters:** Apple's policy enforcement now blocks updates when the declared data categories don't match observed network calls. Shipping the Step 9 + Step 11 waves to production without this update is a real review-rejection risk on the next release.

### Product decisions

- [ ] **(decision needed) Legacy `/speech/pronunciation/evaluate` endpoint — kill, migrate, or leave?** The endpoint still exists and is technically reachable, powered by the old VIP-only Pronunciation tile. Three options: (a) hide the tile + disable the endpoint outright (cleanest, but loses any existing user audio history), (b) hide the tile but keep the endpoint reachable for a deprecation window, (c) leave it alone and rely on the new 🎙️ Pronounce chip displacing usage organically. **Privacy hold is removed** — `jobs/pronunciationAudioPurgeJob.js` purges Spaces blobs after ~27 days and Mongo TTL drops records at 30, so retention is bounded regardless of which option wins. This is purely a UX/sunset call now.
  - **Why this matters:** The longer this drifts, the more we accumulate "three pronunciation experiences" tool sprawl — confusing for users, confusing for us when planning v2 (phoneme-level scoring).

---

## 🛠️ Queued engineering

### Step 15 — Close the memory loop

The §3 status table in `AI_STUDY_PROCESS.md` marks these as ❌ aspirational. They're documented as the future-state moat but aren't wired yet. Queued for their own wave so they don't get bundled into unrelated work.

- [ ] **(30 min) Filter + semantically interpret `pronunciation:` prefix in Chat's system prompt.** Today `services/tutorService.js#buildSystemPrompt` (line ~49) injects weakAreas as a flat string — the AI sees `pronunciation:park` literally and doesn't know it's a phonetic weakness vs a grammar gap. Either filter pronunciation-tagged items out, or tag them in the prompt as "pronunciation weaknesses — encourage saying these words out loud."

- [ ] **(1 hr) Story generation should bias toward weak areas.** Today `services/tutorStoryService.js` only pulls from the `Vocabulary` collection for word selection. Pronunciation-weak words don't appear in stories unless they happen to also be in vocab. Either merge weakAreas into the candidate word pool, or pass them as a separate "extra priority" list to the AI.

- [ ] **(1 hr) Photo chip should bias prompts toward weak areas.** Today `services/tutorImageVocabService.js` describes whatever the user uploads with zero weak-area awareness. Could either: (a) tell the AI to highlight any weak-area words it spots in the photo and offer a vocab card, or (b) proactively suggest "try photographing a [weak word]" between photos.

### Architecture prep

- [ ] **(30 min) Implement OpenAI provider abstraction for future model swap.** Today `services/aiProviderService.js` is OpenAI-only. If model pricing shifts or Claude / Gemini becomes more attractive for one of our use cases (e.g., Whisper alternatives, cheaper vision), swapping is a multi-file change touching every caller. A thin abstraction layer (`callLLM({provider, model, ...})` with provider implementations behind a switch) means future swaps are a config change. Not urgent — flagged as preparation so it doesn't surface as urgent later under cost pressure.

- [ ] **(30 min) AudioCache orphan blob purge.** Mirror `jobs/pronunciationAudioPurgeJob.js`. `AudioCache` Mongo TTL drops records at 90 days; Spaces blobs persist indefinitely. Add a ~87-day Spaces purge job (3-day buffer before Mongo TTL, same pattern as pronunciation purge). Same pattern, different collection. Flagged during the Task 2 storage audit but punted out of scope at the time. Not urgent — at current scale (~1K users), orphan audio is <10GB; becomes worth fixing before 10K DAU.

### Legacy endpoint cleanup (downstream of the product decision above)

- [ ] **(1 hr, once decided) Disable / migrate the legacy `/speech/pronunciation/evaluate` endpoint.** Engineering work after the product decision lands. Specifics depend on which option wins (a/b/c above). If "kill," this is also where we remove the now-unused upload path in `speechService.js#evaluatePronunciation` and the `userAudioUrl` field handling in `PronunciationAttempt`.

---

## ✅ Completed

(none yet — add entries here as you tick items above, with date + a one-liner)
