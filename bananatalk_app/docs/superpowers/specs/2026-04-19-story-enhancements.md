# Story Enhancements — Highlights, Text Stories, Stickers & Overlays

**Date:** 2026-04-19
**Status:** Approved
**Scope:** Backend (language_exchange_backend_application) + Flutter (bananatalk_app)
**Sub-project:** 3 of 3

---

## Overview

Add text-only stories with gradient backgrounds (13 presets), story highlights on user profiles (Instagram-style circles), and text/emoji sticker overlays on photo/video stories. All rendered client-side, no server-side image compositing.

---

## 1. Text Stories

### 1.1 Backend — Story Model Changes

Add to Story schema:
```js
storyType: {
  type: String,
  enum: ['image', 'video', 'text'],
  default: 'image'
},
text: {
  type: String,
  maxlength: 500,
  default: null
},
backgroundColor: {
  type: String,
  enum: ['', 'gradient_sunset', 'gradient_ocean', 'gradient_forest',
         'gradient_purple', 'gradient_fire', 'gradient_midnight',
         'gradient_candy', 'gradient_sky',
         'gradient_neon', 'gradient_coral', 'gradient_gold',
         'gradient_nightclub', 'gradient_arctic'],
  default: ''
},
```

### 1.2 Gradient Presets

Existing 8 (from MomentGradients):
- sunset, ocean, forest, purple, fire, midnight, candy, sky

New 5 story-specific:
- `gradient_neon`: [0xFF00F260, 0xFF0575E6] (green → blue)
- `gradient_coral`: [0xFFFF6B6B, 0xFFEE5A24] (coral → orange)
- `gradient_gold`: [0xFFF7971E, 0xFFFFD200] (gold → yellow)
- `gradient_nightclub`: [0xFF8E2DE2, 0xFFFF6FD8, 0xFF3813C2] (purple → pink → blue)
- `gradient_arctic`: [0xFFE0EAFC, 0xFFCFDEF3] (white → ice blue)

### 1.3 Flutter — Story Creation

- Story creation screen gets a "Text" mode/tab alongside Photo/Video
- Text mode: shows gradient background selector (horizontal scroll of circles) + centered text input
- Font size adjustable via slider or pinch
- Saves as `storyType: 'text'`, `text: content`, `backgroundColor: gradientKey`
- No media upload needed for text stories

### 1.4 Flutter — Story Viewer

- Text stories render as full-screen gradient with centered white text
- Same progress bar, navigation, and reaction UI as image/video stories

---

## 2. Story Highlights

### 2.1 Backend — Highlight Model (new)

```js
const HighlightSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  title: {
    type: String,
    required: true,
    maxlength: 30,
    trim: true
  },
  coverImage: {
    type: String,
    default: null
  },
  stories: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Story'
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});
```

### 2.2 Backend — Story Model Changes

Add to Story schema:
```js
isHighlighted: {
  type: Boolean,
  default: false
}
```

Stories with `isHighlighted: true` are preserved even after 24h expiration — the TTL cleanup job skips them.

### 2.3 Backend — Highlight Endpoints

- `POST /api/v1/highlights` — Create highlight (title, stories array)
- `GET /api/v1/highlights/user/:userId` — Get user's highlights
- `PUT /api/v1/highlights/:id` — Update (add/remove stories, change title/cover)
- `DELETE /api/v1/highlights/:id` — Delete highlight
- When stories are added to a highlight, set `isHighlighted: true` on those stories
- When removed from all highlights, set `isHighlighted: false`

### 2.4 Flutter — Profile Display

- Row of circular highlight covers below bio on profile page
- Each circle: cover image (or first story thumbnail) + title below (max 10 chars + ellipsis)
- "+" button at the start to create new highlight
- Tap highlight → opens story viewer with those stories
- Horizontal scroll if many highlights

### 2.5 Flutter — Managing Highlights

- From story viewer (own stories): three-dot menu → "Add to Highlight"
- Shows existing highlights to add to, or "Create New"
- Create highlight: enter title, auto-selects cover from first story, pick which stories to include
- Edit highlight: long-press on profile → edit title, cover, stories

---

## 3. Stickers & Text Overlays

### 3.1 Backend — Story Model Changes

Add to Story schema:
```js
overlays: [{
  type: {
    type: String,
    enum: ['text', 'sticker'],
    required: true
  },
  content: {
    type: String,
    required: true
  },
  x: { type: Number, default: 0.5 },
  y: { type: Number, default: 0.5 },
  scale: { type: Number, default: 1.0 },
  rotation: { type: Number, default: 0 },
  color: { type: String, default: '#FFFFFF' },
  fontStyle: { type: String, default: 'sans-serif' },
  bgMode: { type: String, enum: ['none', 'semi', 'solid'], default: 'none' }
}]
```

### 3.2 Flutter — Text Overlays

- "Aa" button in story creation (after selecting photo/video)
- Tapping creates a draggable text overlay at center of screen
- Text input with keyboard, live preview on the story
- Controls: font style selector (4 options: sans-serif, serif, bold, handwritten), color picker (8 preset colors: white, black, red, blue, green, yellow, pink, purple), background mode toggle (none/semi-transparent/solid)
- Draggable: pan gesture to move
- Resizable: pinch to scale
- Rotatable: two-finger twist
- Multiple text overlays allowed per story
- Delete: drag to trash icon at bottom

### 3.3 Flutter — Emoji Stickers

- Sticker button (smiley face icon) in story creation
- Opens emoji keyboard
- Selected emoji placed as large element (64px default) at center
- Same drag/pinch/rotate as text overlays
- Multiple stickers allowed

### 3.4 Overlay Rendering

- All overlays rendered client-side using `Stack` + `Positioned` + `Transform`
- Position stored as percentage (0-1) of screen width/height for device independence
- In story viewer, overlays rendered on top of media using same Stack approach
- No server-side compositing — just JSON data

---

## 4. Localization

New strings for all 18 ARB files:

**Text Stories:**
- `textStory` — "Text"
- `typeYourStory` — "Type your story..."
- `selectBackground` — "Select background"

**Highlights:**
- `highlights` — "Highlights"
- `newHighlight` — "New Highlight"
- `highlightTitle` — "Highlight Title"
- `addToHighlight` — "Add to Highlight"
- `createNewHighlight` — "Create New"
- `editHighlight` — "Edit Highlight"
- `deleteHighlight` — "Delete Highlight"
- `selectStories` — "Select Stories"
- `selectCover` — "Select Cover"

**Overlays:**
- `addText` — "Add Text"
- `addSticker` — "Add Sticker"
- `fontStyle` — "Font Style"
- `textColor` — "Text Color"
- `dragToDelete` — "Drag here to delete"

---

## 5. Files to Modify/Create

### Backend (language_exchange_backend_application)
| File | Changes |
|------|---------|
| `models/Story.js` | Add `storyType`, `text`, `backgroundColor`, `isHighlighted`, `overlays` |
| `models/Highlight.js` | NEW — Highlight schema |
| `controllers/highlights.js` | NEW — CRUD for highlights |
| `routes/highlights.js` | NEW — Highlight routes |
| `controllers/stories.js` | Support text story creation, skip highlighted stories in cleanup |

### Flutter (bananatalk_app)
| File | Changes |
|------|---------|
| `lib/providers/provider_models/story_model.dart` | Add storyType, text, backgroundColor, overlays fields |
| `lib/providers/provider_models/moments_model.dart` | Expand MomentGradients with 5 new presets |
| `lib/pages/stories/create_story_screen.dart` | Add text story tab, overlay editor, sticker picker |
| `lib/pages/stories/story_viewer_screen.dart` | Render text stories and overlays |
| `lib/pages/stories/widgets/overlay_editor.dart` | NEW — draggable/resizable overlay widget |
| `lib/pages/profile/main/profile_highlights.dart` | NEW — highlights row on profile |
| `lib/services/highlights_service.dart` | NEW — highlights API service |
| `lib/l10n/app_en.arb` | Add ~17 new strings |
| `lib/l10n/app_*.arb` (17 files) | Add translated versions |

---

## 6. Summary of Key Decisions

1. **13 gradient presets** — 8 existing + 5 new vibrant story-specific
2. **Text stories** — storyType field, gradient background, centered text, no media upload
3. **Highlights** — new model, Instagram-style circles on profile, stories preserved past 24h
4. **Overlays as JSON** — position/scale/rotation stored as percentages, rendered client-side
5. **4 font styles** — sans-serif, serif, bold, handwritten
6. **8 preset colors** — white, black, red, blue, green, yellow, pink, purple
7. **Emoji stickers** — system emoji keyboard, draggable/resizable, no custom packs
8. **No music** — deferred to future sub-project
9. **No server-side compositing** — all rendering is client-side
