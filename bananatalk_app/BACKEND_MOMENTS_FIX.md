# Backend Moments API Error Fix

## Problem
The backend is returning an error: `"processMomentImages is not a function"` when trying to load moments.

## Error Details
- **Error Message**: `processMomentImages is not a function`
- **Endpoint**: `GET /api/v1/moments?page=1&limit=50`
- **Flutter Display**: Shows "Failed to load moments" in UI

## Root Cause
The backend code is trying to call a function `processMomentImages()` that doesn't exist or isn't properly imported/defined.

## Backend Fix Required

### 1. Find Where `processMomentImages` is Being Called

Search your backend code for:
```javascript
processMomentImages
```

### 2. Check Your Moments Controller/Service

Look in files like:
- `controllers/moments.js`
- `services/momentsService.js`
- `routes/moments.js`

### 3. Possible Issues

**Issue 1: Function Not Defined**
```javascript
// ❌ WRONG - Function doesn't exist
const processedImages = processMomentImages(moment.images);

// ✅ FIX - Either define the function or remove the call
// Option A: Define the function
function processMomentImages(images) {
  if (!images || !Array.isArray(images)) return [];
  return images.map(img => {
    // Your image processing logic here
    return img;
  });
}

// Option B: Remove the call if not needed
const processedImages = moment.images || [];
```

**Issue 2: Function Not Imported**
```javascript
// ❌ WRONG - Function not imported
const processedImages = processMomentImages(moment.images);

// ✅ FIX - Import the function
const { processMomentImages } = require('../utils/imageUtils');
// or
const processMomentImages = require('../utils/imageUtils').processMomentImages;
```

**Issue 3: Typo in Function Name**
```javascript
// ❌ WRONG - Typo
const processedImages = processMomentImages(moment.images);

// ✅ FIX - Correct function name
const processedImages = processMomentImageUrls(moment.images);
// or
const processedImages = formatMomentImages(moment.images);
```

### 4. Quick Fix (If Function Not Needed)

If you don't actually need to process images, simply remove the call:

```javascript
// Before
const processedImages = processMomentImages(moment.images);
moment.images = processedImages;

// After
// Just use moment.images directly, no processing needed
```

### 5. Example Backend Code Fix

**If you need image processing:**
```javascript
// utils/imageUtils.js
function processMomentImages(images) {
  if (!images || !Array.isArray(images)) {
    return [];
  }
  
  return images.map(image => {
    // Add your image processing logic here
    // e.g., ensure full URLs, add CDN prefix, etc.
    if (typeof image === 'string') {
      // If image is already a URL, return as is
      if (image.startsWith('http://') || image.startsWith('https://')) {
        return image;
      }
      // Otherwise, add base URL
      return `${process.env.CDN_URL || ''}${image}`;
    }
    return image;
  });
}

module.exports = { processMomentImages };
```

**In your moments controller:**
```javascript
const { processMomentImages } = require('../utils/imageUtils');

// In your getMoments function
const moments = await Moment.find({ /* your query */ });

const processedMoments = moments.map(moment => {
  return {
    ...moment.toObject(),
    images: processMomentImages(moment.images || []),
    imageUrls: processMomentImages(moment.imageUrls || []),
  };
});

return processedMoments;
```

## Testing

After fixing the backend:

1. Restart your backend server
2. Test the moments endpoint:
   ```bash
   curl http://localhost:5000/api/v1/moments?page=1&limit=10
   ```
3. Check that it returns moments without errors
4. Test from Flutter app - moments should load now

## Flutter Error Handling

I've updated the Flutter code to log the actual backend error message, so you'll see the real error in the console instead of just "Failed to load moments".

Look for these logs:
```
❌ Backend error loading moments: processMomentImages is not a function
📡 Response status: 500
📡 Response body: {...}
```

This will help you debug backend issues more easily.

