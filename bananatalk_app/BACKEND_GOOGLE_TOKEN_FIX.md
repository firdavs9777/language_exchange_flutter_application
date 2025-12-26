# Backend Google Sign-In Token Verification Fix

## Problem
The backend is returning `401: Invalid Google token` when verifying Google ID tokens from mobile apps.

## Root Cause
The backend's `audience` array is missing the **Web client ID** that Android uses. The Flutter app uses different client IDs for iOS and Android.

## Current Configuration

### Flutter App (Client)
- **iOS Client ID**: `810869785173-6jl1i1b32lghpsdq6lp92a7b1vuedoh4.apps.googleusercontent.com`
- **Android Web Client ID**: `28446912403-2ba6tssqm95r6iu6cov7c6riv00gposo.apps.googleusercontent.com`
- **Endpoint**: `POST /api/v1/auth/google/mobile`
- **Request Body**: `{ "idToken": "<google_id_token>" }`

### Backend Issue
Your backend code has the iOS client ID in the audience, but is **missing the Android Web client ID**.

## Fix Your Backend Code

### 1. Update Your `.env` File

Set `GOOGLE_CLIENT_ID` to the **Web client ID** (used by Android):

```env
GOOGLE_CLIENT_ID=28446912403-2ba6tssqm95r6iu6cov7c6riv00gposo.apps.googleusercontent.com
```

### 2. Update Your Backend Code

**Current code (missing Android Web client ID):**
```javascript
const ticket = await client.verifyIdToken({
  idToken: idToken,
  audience: [
    process.env.GOOGLE_CLIENT_ID,
    '810869785173-6jl1i1b32lghpsdq6lp92a7b1vuedoh4.apps.googleusercontent.com' // iOS only
  ]
});
```

**Fixed code (includes both iOS and Android):**
```javascript
const ticket = await client.verifyIdToken({
  idToken: idToken,
  audience: [
    process.env.GOOGLE_CLIENT_ID, // Web client ID (for Android)
    '810869785173-6jl1i1b32lghpsdq6lp92a7b1vuedoh4.apps.googleusercontent.com', // iOS client ID
    '28446912403-2ba6tssqm95r6iu6cov7c6riv00gposo.apps.googleusercontent.com' // Web client ID (explicit)
  ]
});
```

### 3. Complete Updated Backend Code

```javascript
exports.googleMobileLogin = asyncHandler(async (req, res, next) => {
  const { idToken } = req.body;
  
  if (!idToken) {
    return next(new ErrorResponse('ID token is required', 400));
  }
  
  try {
    const { OAuth2Client } = require('google-auth-library');
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    
    const ticket = await client.verifyIdToken({
      idToken: idToken,
      audience: [
        process.env.GOOGLE_CLIENT_ID, // Web client ID (Android)
        '810869785173-6jl1i1b32lghpsdq6lp92a7b1vuedoh4.apps.googleusercontent.com', // iOS client ID
        '28446912403-2ba6tssqm95r6iu6cov7c6riv00gposo.apps.googleusercontent.com' // Web client ID (explicit)
      ]
    });
    
    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture } = payload;
    
    console.log('✅ Google token verified:', { googleId, email, name });
    
    // Try to find existing user by Google ID
    let user = await User.findOne({ googleId });
    
    // If not found by Google ID, try by email
    if (!user && email) {
      user = await User.findOne({ email });
      
      // If user exists with this email, link Google account
      if (user) {
        user.googleId = googleId;
        if (picture && (!user.images || user.images.length === 0)) {
          user.images = [picture];
        }
        await user.save();
      }
    }
    
    // If still no user, create new one
    if (!user) {
      user = await User.create({
        googleId,
        email,
        name: name || 'User',
        images: picture ? [picture] : [],
        isEmailVerified: true,
        isRegistrationComplete: true,
        // Default values for required fields (only for new OAuth users)
        gender: 'other',
        bio: 'Hello! I joined using Google. 👋',
        birth_year: '2000',
        birth_month: '1',
        profileCompleted: false,
        birth_day: '1',
        native_language: 'English',
        language_to_learn: 'Korean',
        location: {
          type: 'Point',
          coordinates: [0.0, 0.0],
          formattedAddress: 'Not specified',
          city: 'Not specified',
          country: 'Not specified'
        }
      });
      
      console.log('✅ New Google user created:', user._id);
    } else {
      console.log('✅ Existing user logged in:', user._id);
    }
    
    const deviceInfo = getDeviceInfo(req);
    logSecurityEvent('GOOGLE_MOBILE_LOGIN_SUCCESS', {
      userId: user._id,
      email: user.email,
      ipAddress: deviceInfo.ipAddress
    });
    
    sendTokenResponse(user, 200, res, req, deviceInfo);
    
  } catch (error) {
    console.error('❌ Google mobile auth error:', error);
    return next(new ErrorResponse('Invalid Google token', 401));
  }
});
```

## Summary of Changes

1. **Update `.env` file**: Set `GOOGLE_CLIENT_ID` to the Web client ID
2. **Add Web client ID to audience array**: Include `28446912403-2ba6tssqm95r6iu6cov7c6riv00gposo.apps.googleusercontent.com`
3. **Restart backend server**: After making changes

## Why This Works

- **iOS**: Uses its own client ID (`810869785173-6jl1i1b32lghpsdq6lp92a7b1vuedoh4...`)
- **Android**: Uses the Web client ID (`28446912403-2ba6tssqm95r6iu6cov7c6riv00gposo...`)
- **Backend**: Must accept tokens from both by including both in the `audience` array

## Testing

After updating:

1. Update `.env` with the Web client ID
2. Update the backend code with the new audience array
3. Restart backend: `pm2 restart language-app` (or your restart command)
4. Test Google Sign-In from Android device
5. Test Google Sign-In from iOS device

Both should work now! ✅
