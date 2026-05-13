# Manual TODOs — humans only

Things only you can do (decisions, dashboard config, real-device tests, App Store stuff).
Agents can't tick these off; add a new section at the bottom with date + note when you complete one.

---

## Open

### Step 11 — Pronunciation Coach

- [ ] **Two-device smoke test pass.** Build the latest `main` on a real iPhone and a real Android. Walk: AI Study tab #1 → tap 🎙️ Pronounce → 5-sentence drill happy path → 1 deliberate mispronunciation → 1 silent recording → custom-sentence path → mid-session back-press confirm dialog → mic permission denied path. Verify `GET /tutor/me` shows `pronunciation:<word>` in `weakAreas` after Save & Close.

### Step 9 — AI Tutor wave (carryover)

- [ ] **Two-device smoke test (iOS sim + physical Android).** Verify the four Step 9 chips (Chat, Roleplay, Story, Photo) work on both devices end-to-end with real OpenAI calls.
- [ ] **Voice routing with Bluetooth headset.** Test chat voice mode + Pronounce while AirPods or another BT headset is connected. Confirm audio routes through the headset and the iOS audio session category transition from chat → record doesn't blow up.
- [ ] **GPT-4o vision end-to-end test with prod OpenAI key.** Take a real photo through the 📷 Photo chip on a physical device. Confirm describe + grade both work. Sub-test: a HEIC image from iOS Photos library.
- [ ] **OpenAI budget alert at $100/month on the dashboard.** Visit https://platform.openai.com/account/limits and set a soft + hard cap. Without this, a runaway prompt loop could rack up real money before we notice.
- [ ] **Privacy policy delta filed with App Store + Play Store.** The user-facing privacy section in §10 of `AI_STUDY_PROCESS.md` should be reflected in the store privacy answers, especially the "voice samples leave the device" part.

### Step 11 follow-up (legacy)

- [ ] **Decide fate of legacy `/speech/pronunciation/evaluate` endpoint.** Currently uploads user audio to Spaces. Dormant in the current Flutter main flow but reachable. Either: hide the old Pronunciation tile (Step 13 sunset) AND disable the endpoint, OR migrate the data and disable. Documented in §10 of `AI_STUDY_PROCESS.md`.

---

## Completed

(none yet — add entries here as you tick items above)
