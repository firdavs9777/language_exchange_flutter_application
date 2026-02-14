# Backend Translation Endpoints - Implementation Guide

This document outlines the backend endpoints for the translation feature using **LibreTranslate** (free, open-source translation service).

## Required Endpoints

### 1. Moment Translation Endpoint

**Endpoint:** `POST /api/v1/moments/:momentId/translate`

**Auth:** Required (Bearer token)

**Request Body:**
```json
{
  "targetLanguage": "en"  // ISO 639-1 language code (e.g., 'en', 'zh', 'ko', 'ru', 'es', 'ar')
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "language": "en",
    "translatedText": "This is the translated moment text",
    "translatedAt": "2025-01-18T10:30:00.000Z"
  },
  "cached": false
}
```

**Notes:**
- Uses LibreTranslate (free, open-source translation service)
- Caches translations in database to avoid redundant API calls
- Returns existing translation if already cached
- Detects source language automatically or uses moment's language field

---

### 2. Comment Translation Endpoint

**Endpoint:** `POST /api/v1/comments/:commentId/translate`

**Auth:** Required (Bearer token)

**Request Body:**
```json
{
  "targetLanguage": "en"  // ISO 639-1 language code
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "language": "en",
    "translatedText": "This is the translated comment text",
    "translatedAt": "2025-01-18T10:30:00.000Z"
  },
  "cached": false
}
```

**Notes:**
- Uses LibreTranslate (free, open-source translation service)
- Caches translations in database
- Returns existing translation if already cached
- Detects source language automatically or uses comment author's native language

---

### 3. Get Moment Translations Endpoint (Optional)

**Endpoint:** `GET /api/v1/moments/:momentId/translations`

**Auth:** Required (Bearer token)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "language": "en",
      "translatedText": "English translation",
      "translatedAt": "2025-01-18T10:30:00.000Z"
    },
    {
      "language": "zh",
      "translatedText": "中文翻译",
      "translatedAt": "2025-01-18T10:30:00.000Z"
    }
  ]
}
```

---

### 4. Get Comment Translations Endpoint (Optional)

**Endpoint:** `GET /api/v1/comments/:commentId/translations`

**Auth:** Required (Bearer token)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "language": "en",
      "translatedText": "English translation",
      "translatedAt": "2025-01-18T10:30:00.000Z"
    }
  ]
}
```

---

## LibreTranslate Setup

### Default Configuration (No setup required)
- Uses public LibreTranslate instance: `https://libretranslate.com`
- No API key needed
- Completely free to use

### Optional: Custom LibreTranslate Instance

If you want to host your own LibreTranslate instance for better performance or privacy:

1. Set up your own LibreTranslate server (see [LibreTranslate GitHub](https://github.com/LibreTranslate/LibreTranslate))
2. Add to your `.env` file:

```env
LIBRETRANSLATE_URL=https://your-libretranslate-instance.com
```

### Supported Languages

LibreTranslate supports many languages including:
- `en` - English
- `zh` - Chinese
- `ko` - Korean
- `ru` - Russian
- `es` - Spanish
- `ar` - Arabic
- `fr` - French
- `de` - German
- `ja` - Japanese
- `pt` - Portuguese
- `it` - Italian
- `hi` - Hindi
- `th` - Thai
- `vi` - Vietnamese
- `id` - Indonesian
- `tr` - Turkish
- `pl` - Polish
- `nl` - Dutch
- `sv` - Swedish
- `da` - Danish
- `fi` - Finnish
- `no` - Norwegian
- And more...

---

## Database Schema

### Translation Model

```javascript
{
  sourceId: ObjectId,  // ID of the moment or comment
  sourceType: String, // 'moment' or 'comment'
  sourceLanguage: String, // Original language code
  targetLanguage: String, // Target language code
  translatedText: String, // Translated content
  provider: String, // 'google', 'deepl', etc.
  cached: Boolean,
  cachedAt: Date,
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `{ sourceId: 1, sourceType: 1, targetLanguage: 1 }` - Unique compound index for fast lookups
- `{ cachedAt: 1 }` - TTL index for cache expiration (30 days)

---

## Implementation Notes

1. **Translation Service**: Uses **LibreTranslate** (free, open-source, no API key required)
   - Default: Public instance at `https://libretranslate.com`
   - Optional: Configure custom instance via `LIBRETRANSLATE_URL` in `.env`
2. **Caching**: Cache translations in database to reduce API calls (30-day TTL)
3. **Error Handling**: Return appropriate error messages if translation fails
4. **Rate Limiting**: Subject to general rate limiter (500 requests per 15 min per IP)
5. **Language Detection**: Auto-detect source language if not provided
6. **Supported Languages**: LibreTranslate supports many languages including: en, zh, ko, ru, es, ar, fr, de, ja, pt, it, hi, th, vi, id, tr, pl, nl, sv, and more
7. **Cost**: **Completely free** - no API costs with LibreTranslate

---

## Flutter Integration

The Flutter app is already configured to call these endpoints:

- `Endpoints.translateMomentURL(momentId)` → `moments/:momentId/translate`
- `Endpoints.translateCommentURL(commentId)` → `comments/:commentId/translate`
- `Endpoints.getMomentTranslationsURL(momentId)` → `moments/:momentId/translations` (optional)
- `Endpoints.getCommentTranslationsURL(commentId)` → `comments/:commentId/translations` (optional)

The app expects the response format shown above. The `MessageTranslation` model in Flutter matches the response structure.

---

## Testing

Test the endpoints with:

```bash
# Translate a moment
curl -X POST https://api.banatalk.com/api/v1/moments/{MOMENT_ID}/translate \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"targetLanguage": "en"}'

# Translate a comment
curl -X POST https://api.banatalk.com/api/v1/comments/{COMMENT_ID}/translate \
  -H "Authorization: Bearer {TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"targetLanguage": "zh"}'
```

---

## LibreTranslate Setup

### Default Configuration (No setup required)
- Uses public LibreTranslate instance: `https://libretranslate.com`
- No API key needed
- Free to use

### Optional: Custom LibreTranslate Instance

If you want to host your own LibreTranslate instance:

1. Set up your own LibreTranslate server (see [LibreTranslate GitHub](https://github.com/LibreTranslate/LibreTranslate))
2. Add to your `.env` file:

```env
LIBRETRANSLATE_URL=https://your-libretranslate-instance.com
```

## Required Backend Files

Based on the documentation, the following files should be created:

- `models/Translation.js` - Translation model with caching
- `services/translationService.js` - Translation service logic using LibreTranslate
- `controllers/moments.js` - Added `translateMoment` and `getMomentTranslations`
- `controllers/comments.js` - Added `translateComment` and `getCommentTranslations`
- `routes/moments.js` - Added translation routes
- `routes/comment.js` - Added translation routes
- `validators/translationValidator.js` - Validation for translation requests

## Backend Files Required

Based on the API documentation provided, the following backend files should be created:

- `models/Translation.js` - Translation model with caching
- `services/translationService.js` - Translation service logic using LibreTranslate
- `controllers/moments.js` - Added `translateMoment` and `getMomentTranslations`
- `controllers/comments.js` - Added `translateComment` and `getCommentTranslations`
- `routes/moments.js` - Added translation routes
- `routes/comment.js` - Added translation routes
- `validators/translationValidator.js` - Validation for translation requests

## Cost Considerations

- **LibreTranslate is completely free** - no API costs
- Uses public instance: `https://libretranslate.com`
- Caching reduces API calls and improves performance
- No rate limits (but be respectful of the public service)
- Option to host your own instance for unlimited usage

## Status

- ✅ Flutter app implementation complete
- ✅ Backend API documentation provided (using LibreTranslate)
- ⏳ Backend implementation in progress
- ⏳ Database schema needs to be added

