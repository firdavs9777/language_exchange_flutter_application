# LibreTranslate Backend Configuration Fix

## Issue

The backend is showing an error: "LibreTranslate API error: Visit https://portal.libretranslate.com to get an API key"

## Solution

The public LibreTranslate instance at `https://libretranslate.com` may require an API key for certain operations. Here are the options:

### Option 1: Use LibreTranslate Without API Key (Recommended for Development)

The public LibreTranslate instance should work without an API key for basic translations. Make sure your backend code doesn't require an API key when using the public instance.

**Backend Code Check:**
- Ensure the translation service doesn't send an `api_key` parameter when using the public instance
- The public instance should work with just the text, source language, and target language

**Example Request (No API Key):**
```javascript
const response = await axios.post('https://libretranslate.com/translate', {
  q: text,
  source: sourceLanguage,
  target: targetLanguage,
  format: 'text'
});
```

### Option 2: Get a Free API Key (Recommended for Production)

1. Visit https://portal.libretranslate.com
2. Sign up for a free account
3. Get your API key
4. Add to your backend `.env` file:

```env
LIBRETRANSLATE_API_KEY=your_api_key_here
LIBRETRANSLATE_URL=https://libretranslate.com
```

**Backend Code Update:**
```javascript
// ✅ CORRECT - Only sends api_key if you have one
const requestBody = {
  q: text,
  source: sourceLanguage,
  target: targetLanguage,
  format: 'text'
};

// Only add api_key if it exists
if (process.env.LIBRETRANSLATE_API_KEY) {
  requestBody.api_key = process.env.LIBRETRANSLATE_API_KEY;
}

const response = await axios.post(`${libreTranslateUrl}/translate`, requestBody);
```

### Option 3: Host Your Own LibreTranslate Instance (Best for Production)

For unlimited usage and better privacy:

1. Set up your own LibreTranslate server (Docker recommended)
2. Update your `.env`:

```env
LIBRETRANSLATE_URL=https://your-libretranslate-instance.com
# No API key needed for self-hosted instance
```

## Backend Service Code Example

Here's how the translation service should handle API keys:

```javascript
// services/translationService.js
const axios = require('axios');

const LIBRETRANSLATE_URL = process.env.LIBRETRANSLATE_URL || 'https://libretranslate.com';
const LIBRETRANSLATE_API_KEY = process.env.LIBRETRANSLATE_API_KEY;

async function translateText(text, sourceLanguage, targetLanguage) {
  try {
    // ✅ CORRECT - Only sends api_key if you have one
    const requestBody = {
      q: text,
      source: sourceLanguage || 'auto',
      target: targetLanguage,
      format: 'text'
    };

    // Only add api_key if it exists
    if (LIBRETRANSLATE_API_KEY) {
      requestBody.api_key = LIBRETRANSLATE_API_KEY;
    }

    const response = await axios.post(`${LIBRETRANSLATE_URL}/translate`, requestBody, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    return {
      success: true,
      translatedText: response.data.translatedText,
      detectedLanguage: response.data.detectedLanguage?.language
    };
  } catch (error) {
    console.error('LibreTranslate error:', error.response?.data || error.message);
    
    // Return user-friendly error
    return {
      success: false,
      error: 'Translation service temporarily unavailable. Please try again later.'
    };
  }
}
```

## Error Handling

The backend should return user-friendly error messages instead of technical API errors:

```javascript
// Instead of:
error: 'LibreTranslate API error: Visit https://portal.libretranslate.com to get an API key'

// Return:
error: 'Translation service is being configured. Please try again later.'
```

Or better yet, handle the error gracefully and don't expose technical details to the frontend.

## Testing

After updating the backend:

1. Test without API key (should work with public instance)
2. Test with API key (if you got one)
3. Verify error messages are user-friendly
4. Check that translations are being cached properly

## Status

- ✅ Flutter app now shows user-friendly error messages
- ⏳ Backend needs to be updated to handle LibreTranslate API key properly
- ⏳ Backend should return user-friendly error messages instead of technical errors

