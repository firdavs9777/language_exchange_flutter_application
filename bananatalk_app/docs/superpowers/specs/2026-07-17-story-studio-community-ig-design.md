# Story Studio + Instagram-style Community Detail + Moments Freshness — Design

**Date:** 2026-07-17
**Scope decision (user):** Option C — full six-feature story editor in one workstream, plus
Instagram-style community detail redesign (display-only stat counters, option B), story
rings in the community list, and moments feed freshness. "Instagram-like but not 100%
the same" — keep BananaTalk identity (teal/banana accents, language badges, wave).

---

## Part 1 — Story Studio (create-screen rebuild)

The backend `Story` model already supports everything in F1–F3 (`overlays[]` with
x/y 0–1, scale 0.5–3.0, color, fontStyle enum; geo-indexed `location`; `hashtags[]`).
The current app sends one centered overlay hardcoded to `#FFFFFF` — that is the bug
that makes story text "always white."

### F1. Canvas text editor (app-only)
- Tap anywhere on the canvas → new text overlay in edit mode (keyboard up, centered).
- Drag to move; pinch to scale (clamped 0.5–3.0 to match backend validation).
- Per-overlay: color (12-swatch palette + white/black), fontStyle
  (sans-serif / serif / bold / handwritten — the backend enum), emoji overlays.
- Multiple overlays; long-press → delete (drag to trash zone like IG).
- Overlays serialize into the existing `overlays[]` field; the viewer already needs a
  matching render pass (Positioned + FractionalOffset from x/y, Transform.scale).
- Rotation: backend has no rotation field — **descoped**; note added to model as a
  possible follow-up (additive `rotation` Number, default 0).

### F2. Image editing (app-only)
- Crop/rotate via the already-shipped `image_cropper` before compose.
- Filter presets: 6 ColorFiltered matrices (none, warm, cool, mono, fade, vivid)
  applied to the base image at render + baked in on upload via `ColorFilter` →
  RepaintBoundary capture. No new deps.

### F3. Location sticker
- Place picker sheet: device geolocation (geolocator, already shipped) + geocoding
  reverse lookup for name; free-text search via the existing geocoding package.
- Renders as a tappable pill overlay; stored in existing `Story.location`.

### F4. @Mentions (backend + app)
- Backend: additive `mentions: [{ user: ObjectId, x, y, scale }]` on Story +
  validation (max 5, must exist); notification (`story_mention`) through the
  existing notification service, capped via notificationCaps.
- App: "@" sticker → search followers/followings (existing community search),
  renders as pill; tap in viewer → SingleCommunity profile.

### F5. Send story to friends in-app
- Backend: reuse story-reply plumbing — new message subtype `story_share`
  carrying storyId + preview (thumbnail/text, owner). Message renders as a story
  card in chat; tap opens the story viewer if still active, else "story expired".
- App: paper-plane on the viewer → friends picker (recent chats + search) →
  sends via existing ChatSocketService/message API.
- Privacy: server rejects sharing stories the recipient could not view
  (close-friends/friends checks at open time, mirror of feed filtering).

### F6. Drawing tool
- CustomPaint freehand: pen + highlighter, 8 colors, width slider, undo stack.
- Strokes are flattened into the uploaded media (RepaintBoundary capture) — NOT
  stored structurally; keeps backend untouched and viewers simple.
- Text-type stories: drawing available over the gradient background too.

**Editor architecture:** new `story_studio/` folder:
`story_canvas.dart` (gesture + overlay stack), `overlay_model.dart`,
`text_overlay_editor.dart`, `draw_layer.dart`, `filter_bar.dart`,
`location_picker_sheet.dart`, `mention_picker_sheet.dart`. The existing
`create_story_screen.dart` keeps media pickup, privacy dropdown, polls/questions/
hashtags; the canvas replaces the single text-overlay flow.

---

## Part 2 — Community detail, Instagram-style (option B)

Existing modular files (`single_community_header/actions/about/moments/topics`)
are restyled, not rewritten:

- Header row: avatar (with story ring if active) left; **Posts · Followers ·
  Following** counters right — display-only in this workstream.
- Name + language line (native → learning with flags) + collapsed bio ("more").
- Full-width action row: Follow / Message / 👋 Wave.
- Highlights row: reuse existing profile highlights widget for this user.
- Tabs: 📷 Moments (3-col grid; text moments render as colored text tiles — same
  component pattern as profile) · ℹ️ About (about + topics folded together).

## Part 2b — Story rings in Community list
- Backend: `hasActiveStory` boolean added to community list/detail payloads,
  computed per-viewer with privacy respected (public for strangers; friends
  privacy when the viewer follows/is followed per existing feed rules). One
  aggregated lookup (users → active stories) per page, not N+1.
- App: `story_gradient_ring.dart` wraps avatars in community cards/tiles when
  `hasActiveStory`; tap avatar → story viewer (existing route), tap elsewhere →
  profile as today.

---

## Part 3 — Moments feed freshness
- Problem: feed providers cache until manual invalidate; feed feels stale.
- Fix: stale-while-revalidate — record fetch time per feed provider; re-fetch
  automatically when (a) the Moments tab regains visibility or (b) data is older
  than 60s at next build; always keep current list rendered (skipLoadingOnRefresh/
  Reload — same pattern as comments). Pull-to-refresh unchanged.
- No backend change; no polling loop (battery/API cost).

---

## Error handling
- Overlay serialization failures → block post with toast, never silently drop
  (matches workstream-C silent-drop fixes).
- Story share to expired story → chat card shows "Story expired" state.
- Location permission denied → picker falls back to search-only.

## Testing
- Unit: overlay model serialization (x/y/scale clamps), filter matrix map,
  mention validation (backend), hasActiveStory privacy filtering (backend).
- `flutter analyze` clean; backend `node --check` + existing test suite.

## Out of scope
- Overlay rotation (no backend field), story music, GIF stickers, AR effects.
- Making follower/following counters tappable on other users (option A — later).
