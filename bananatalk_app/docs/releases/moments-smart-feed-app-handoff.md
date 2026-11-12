# Moments smart feed (app side, Plan A2) - handoff

Branch `feat/moments-smart-feed-app` (merge base 5cd51acd). Not built, not versioned, not submitted. Nothing is pushed by the implementer; the controller pushes.

This build is the app half of the server's "smart feed" work. Most of it stays invisible until the server switches are turned on.

## 1. What changes for users the moment this build ships (server as it is today, all switches off)

The intended, visible changes:

1. **The feed loads 12 posts per page instead of 50.** Scrolling to the end loads the next 12. If the next page fails (bad connection), the list stays and a "Couldn't load more posts / Retry" row appears instead of the posts silently stopping. Search still loads 50 and Trending still loads 10.
2. **Cached-first feed.** On opening the app the last feed (up to 12 posts) appears at once, then refreshes in place. Only that first open paints from the cache: later refreshes (after a like, comment or save, pull-to-refresh, returning to the tab, after posting) keep the list on screen until the new page arrives, so a like or a deleted post never flips back. If the refresh on opening fails, the cached posts stay. The cache is per user and is wiped on sign-out. A blocked or muted person's post never shows from the cache: blocking someone removes their posts from it at once, the cached list waits for the block and mute lists, and when the block list cannot be fetched (offline) the last list fetched for this user is used (so on a cold start the list can appear a moment later than the cache alone would allow).
3. **New loading looks.** The first load of the feed shows 6 grey "skeleton" cards instead of a spinner. The stories bar shows 5 skeleton rings while loading and also paints its last known rings at once (stories that have expired since are dropped, and so are rings left with none; blocked people are filtered the same way as the feed), then refreshes.
4. **Quiet "opened" signal.** The app tells the server which posts you opened (detail opened, or a long caption expanded), in batches. The server ignores it while its switch is off.

Also (mostly invisible): on Wi-Fi/Ethernet only, the stories bar downloads the first story of its first three rings into the image disk cache (nothing is decoded); the story viewer downloads the next story's picture and the next person's first story (on mobile data, only the next story). Opening a moment (push or link) whose moment is gone now goes back to the screen it was opened from, or on a cold start to the Moments tab, with "Moment not found" (see Section 4 for the exact scope).

Everything else (blurred previews, small avatars, Discover rings, hashtags, clear interests, share offers) activates only when the server sends the new data or turns on its app flag.

## 2. What appears with each server switch

| Server switch | App side | What users see |
|---|---|---|
| `IMAGE_VARIANTS_ENABLED` | none | Server only generates smaller images on upload. Nothing in the app. |
| `FEED_THUMBNAILS_ENABLED` | none needed (app uses `imageVariants` / `avatarThumb` whenever a response carries them; the app flag `feedThumbnailsEnabled` is parsed but is not an entry point) | A blurred preview, then the smaller feed-size image, in the feed and moment detail; in the story viewer the blurred preview, then the feed-size image, then the original once loaded; small avatars in the moment header and stories rail. Full-screen viewer still opens the original. |
| `STORY_DISCOVER_ENABLED` | app flag `storyDiscoverEnabled` | "Discover" rings (people you do not follow) in the stories bar, ordered: unseen followed, Discover, seen followed. Discover rings show a "Discover" label instead of progress dots. |
| `HASHTAGS_ENABLED` | app flag `hashtagsEnabled` | Tappable hashtags in the feed caption, moment detail and saved moments; the hashtag page (`/hashtag/<tag>`, Top/Recent, post count, related-topic banner); trending tags when Moments search is opened empty; tag suggestions when you type `#xx` in search; suggested tags (up to 3 chips) in the composer and suggestions in the tag dialog. The hashtag page hides muted and blocked authors like the feed. Off: the endpoints answer 404 and none of this shows. |
| `INTEREST_RANKING_ENABLED` | app flag `interestRankingEnabled` | A "Clear my interests" row in Settings > Data & storage (confirm, spinner that Android back cannot close, "done" message, feeds refresh and the cached first page is cleared; the request gives up after 10 s). |
| `FEEDBACK_ROUTING_ENABLED` | none (push only) | The `moment_needs_feedback` push opens that moment (no id: Moments tab). No badge on cards. |
| `PROMPT_PUSH_ENABLED` | none (push only) | The `daily_prompt` push opens the composer with today's prompt (signed in = a stored token, so a cold start does not bounce to login while the token is validated; no token: login). |
| (share offers; server hides them through the app flag) | app flag `shareOffersEnabled` | One-tap "share as a moment" card after a lesson result, at a 7 / 30 / 100 day streak celebration, and under a correction of your OWN message (1 offer a day; two dismissals in a row hide it for 7 days). |
| `SMART_FEED_ENABLED` | none | New ranking on the server. The app already sends the server's reel/feed paging cursor back unchanged. |
| `STORY_RAIL_RANKING_ENABLED`, `POST_REWARDS_ENABLED`, `AUTO_TOPICS_ENABLED`, `STORY_STICKER_*`, `STORY_INSIGHTS_ENABLED` | none in this build | Server only (stickers and insights are Plan B). |
| `FEED_IGNORED_PENALTY_ENABLED` | none | See Section 7: wait. |

## 3. What is NOT in this build

- **Reels playback items (task 6 was reduced).** Only the reel paging-cursor pass-through (with a test) is done. NOT built: showing the poster until the first video frame, the controller preload depth, and the reel "comments opened" hook (so opening reel comments is not reported as an open; watching a reel through is still reported by the server side). Reason: branch `perf/reels-playback-r1` (another agent, unmerged) rewrites the files involved. Check and add these after that branch merges.
- A "needs feedback" badge on cards (the server ranks and notifies; no UI was specified).
- Stories features: learning stickers, queued story upload, insights (Plan B, not written).
- Web client changes. Release build, version bump, store submission.

## 4. Known open issues (most important first)

**Could confuse a user**
1. A network failure on a moment push: the ruling is that only a genuinely missing moment (404 / not success) goes to Moments with "Moment not found"; any other failure keeps the old error page. Device-check it (Section 5).
2. The cached feed shows old like/comment counts until the refresh lands. Pull-to-refresh briefly shows the old list instead of the skeleton.
3. If the block-list request never answers (no error, no reply), the cached feed stays on the skeleton until it does; the stories rail waits at most 3 s and then uses the last fetched list. A failing request is fine: both use the last fetched list. (`moments_main.dart`'s legacy `filteredMomentsProvider` also reads the block provider without the gate.)
4. Discover rings show a label instead of per-story dots.
5. Gradient-post captions on the detail screen and saved-card captions are not tappable hashtags. The hashtag page has no pull-to-refresh and shows the tag as normalised, not as typed, until loaded.
6. Reels tab search never shows trending/suggestions (by design). Share-offer streak card could overlap the celebration button on very short screens (< 480 px). The streak offer shows only while the Learn screen is open; prefill language is the user's learning language.
7. Other avatar sites (chat list, community cards, profile) and other image lists (e.g. profile moments) still load full-size images. The carousel frame ratio comes from the first image only. Full-screen video open is not counted as "opened".

**Could cost performance / rare glitches**
8. Auto-fill near the list end can chain up to 4x more requests than before when client-side filters hide whole pages.
9. (Fixed in the final-review wave: a load-more in flight across a reload no longer writes the stale list or skips a page, on the hashtag page and the feed.)
10. Server vs app tag normalisation for unusual characters (superscripts, a zero-width non-joiner ending a tag) is unverified.
11. The composer's `#` suggestion chips and tag dialog: no widget test for the 5-tag cap; `#!!` runs no search.
12. `Community.toJson` does not write `avatarThumb` (falls back to the full image).

**Test and code hygiene (low)**
13. Some tests use fixed 50-100 ms delays (possible CI flake). No tests of the feed-open tracker provider wiring or sign-out clearing of the feed cache; the lesson results share offer is tested through `lessonResultsLayout`, not the whole lesson screen. `ShareOfferPolicy.recordShown` is public and unused (calling it would block that day's offer). The share-offer day is claimed when the card is built, not when seen. A signed-out `daily_prompt` tap loses the composer target after login.
14. Pre-existing and not ours: `test/services/session_reset_test.dart` fails the same way on main (`alreadyWavedProvider`, `userMomentsPagedProvider`, `userMomentsTotalProvider` unclassified).
15. About 61 files under `lib/providers` carry uncommitted formatting-only changes from an earlier accident (not part of any commit). The owner decides whether to discard them (`git checkout -- lib/providers`).

## 5. Device checks before release

Do these on a real phone (Android and iOS where noted), with the server in its current all-off state unless a step says a flag.

- [ ] **Cold start with network:** force-quit the app, open it: the last feed shows at once, then refreshes in place with no jump to the top.
- [ ] **Cold start without network:** force-quit, turn on airplane mode, open: the last posts show; no endless spinner. Stories rail: last rings show too, without rings whose stories have expired. Pull to refresh while still offline: the "failed to load moments" error page replaces the posts (as in the current release); the next successful refresh brings them back.
- [ ] **Block, then cold start offline:** block someone whose post is in the first page and who has a story ring; force-quit, airplane mode, open: neither their post nor their ring appears.
- [ ] **Like while the first page refreshes:** like a post in the first page right after opening the app: the heart and count never flip back.
- [ ] **Sign out and in as another user:** sign out, sign in as a different account. Confirm no previous user's feed, stories rail, hashtag page or trending list appears, even for a moment.
- [ ] **Slow connection mid-scroll:** scroll the feed, turn on airplane mode at the end of a page: a "Couldn't load more posts / Retry" row appears; turn network on, tap Retry: it shows a spinner then the next posts.
- [ ] **Dark-mode skeletons:** switch the phone to dark mode, sign out/in or clear app data: the feed skeleton cards and the stories skeleton rings are dark, not white flashes.
- [ ] **Post with 3 images when the server sends 1 variant** (needs `FEED_THUMBNAILS_ENABLED`, or a test server): image 1 blurs then sharpens; images 2 and 3 show their normal image with no blank space or crash; the full-screen viewer shows originals.
- [ ] **Discover ring** (`STORY_DISCOVER_ENABLED`): ring appears after unseen followed stories with the "Discover" label; tapping opens the viewer and swiping continues over the whole rail; a blocked user's ring never flashes from the cache.
- [ ] **Hashtag page `#한국어`** (`HASHTAGS_ENABLED`): tap `#한국어` in a caption: the page opens with the right title and count, Top/Recent work. Also a tag with a percent sign (e.g. `#100%`): opens the page or its empty state with no crash.
- [ ] **Search and composer** (`HASHTAGS_ENABLED`): open Moments search empty: trending tags show; type `#ko`: suggestions with counts; tap a row opens the page. In the composer, chips follow the caption and are disabled at 5 tags.
- [ ] **Both pushes from a killed app:** force-quit, send `moment_needs_feedback` and `daily_prompt` pushes, tap each: the moment opens; the composer opens with today's prompt. Repeat with the app in the background. A push for a deleted moment lands on Moments with "Moment not found".
- [ ] **Offline tap on a like notification:** airplane mode, tap a like notification: the error page shows (not "Moment not found").
- [ ] **Share offers** (`shareOffersEnabled` on): finish a lesson: the offer shows below the buttons. Reach a 7/30/100-day streak celebration: the offer shows. Receive a correction on YOUR OWN message: the offer shows under it (prefill is only the corrected sentence). Confirm NO offer appears on a correction you wrote yourself, and none in a group chat. Dismiss twice in a row on two days: nothing for 7 days. Accept: the composer opens with the text.
- [ ] **Clear my interests** (`interestRankingEnabled` on): Settings > Data & storage: row shows only with the flag; confirm, see the done message, the feed refreshes.
- [ ] **Small phone / dark mode:** share card and Retry row at 320 px width, no overflow.

## 6. New strings needing native review

All 19 languages were machine-drafted; the 18 non-English ones need a native check. Plural forms exist for `hashtagPostCount` (ru one/few/many/other, ar zero..other, one/other for de/es/fr/it/pt/hi/tg/tl/tr, other only for id/ja/ko/th/vi/zh/zh_TW). Least certain: Russian "Обзор" and Tajik "Кашф" for Discover; de/it "Top" was changed to "Beliebt" / "Popolari".

- Task 3: `feedCouldNotLoadMore`
- Task 7: `storiesDiscoverLabel`
- Task 9: `hashtagPostCount`, `hashtagSortTop`, `hashtagSortRecent`, `hashtagEmpty`, `hashtagShowingRelated`
- Task 10: `hashtagTrendingTitle`, `hashtagSuggestedTitle`
- Task 11: `clearInterestsTitle`, `clearInterestsSubtitle`, `clearInterestsConfirm`, `clearInterestsAction`, `clearInterestsDone`
- Task 12: `shareAsMomentTitle`, `shareAsMomentAction`, `shareOfferLessonText` ({lesson}), `shareOfferStreakText` ({days})

(Tasks 1, 2, 4, 5, 6, 8 added no strings.)

## 7. Server-side dependency

Do NOT turn on `FEED_IGNORED_PENALTY_ENABLED` on the server until this build is widely installed. It penalises posts that were shown but never opened; only builds with the "opened" signal (Section 1, item 4) report opens, so older app versions would look as if they ignore everything.

## 8. Reels branch and merge note

`perf/reels-playback-r1` (unmerged) rewrites `reel_controller_pool.dart`, `reels_feed_screen.dart`, `reel_prefetch_policy.dart`, replaces `reel_video_cache.dart` with a file cache / media scheduler, adds `widgets/reel_player_surface.dart`, and edits `lib/providers/provider_models/moments_model.dart` and `storage_service.dart`. This branch also edits `moments_model.dart` (adds `imageVariants`, `hashtags`, `topics`, `needsFeedback`), but the two sets of changes **merge cleanly**. The one textual conflict is the end of `docs/REMAINING_WORK.md`: keep both sides. That branch changes `MomentVideo.duration` from `int?` to `double?`; nothing on this branch reads it. It does not touch `reels_api_client.dart`. After it merges, re-check the three reel items in Section 3 (its player surface and scheduler likely cover poster-until-first-frame and preload depth).

## 9. Checks run on this branch

After the final-review fix wave: `flutter analyze`: 1130 issues, 0 errors, 3 warnings (unused imports / parameter in `test/chat/chat_state_edit_failed_test.dart` and `test/moments/moments_main_layout_test.dart`, not touched by this branch's fixes); the rest is info-level. `flutter test`: 3612 passed, 1 failed: `test/services/session_reset_test.dart`, which fails identically on main (`alreadyWavedProvider`, `userMomentsPagedProvider`, `userMomentsTotalProvider` unclassified).
