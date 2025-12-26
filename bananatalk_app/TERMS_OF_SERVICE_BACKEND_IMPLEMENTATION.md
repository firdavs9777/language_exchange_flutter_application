# Terms of Service Backend Implementation Guide

## Overview
This document outlines the backend requirements for implementing Terms of Service acceptance functionality to meet App Store compliance (Guideline 1.2).

## Required Changes

### 1. User Model Update

Add a new field to your user model/schema:

```javascript
{
  termsAccepted: {
    type: Boolean,
    default: false,
    required: true
  },
  termsAcceptedDate: {
    type: Date,
    default: null
  }
}
```

**Important:** 
- Default value must be `false` for all existing and new users
- This ensures all users must accept terms before using the app

### 2. API Endpoint

#### Endpoint: `POST /api/v1/auth/accept-terms`

**Purpose:** Update user's terms acceptance status

**Authentication:** Required (Bearer token)

**Request Headers:**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "termsAccepted": true,
  "termsAcceptedDate": "2025-12-15T10:30:00.000Z"
}
```

**Response (Success - 200/201):**
```json
{
  "success": true,
  "message": "Terms accepted successfully",
  "data": {
    "termsAccepted": true,
    "termsAcceptedDate": "2025-12-15T10:30:00.000Z"
  }
}
```

**Response (Error - 400/401/500):**
```json
{
  "success": false,
  "message": "Failed to accept terms",
  "error": "Error details here"
}
```

**Implementation Notes:**
- Verify user is authenticated
- Update user document: set `termsAccepted = true` and `termsAcceptedDate = current timestamp`
- Return success response with updated data

### 3. User Data Response Update

Ensure the `termsAccepted` field is included in all user data responses, especially:

#### `GET /api/v1/auth/me`
Must include `termsAccepted` in the response:

```json
{
  "success": true,
  "data": {
    "_id": "user_id",
    "name": "User Name",
    "email": "user@example.com",
    "termsAccepted": false,
    "termsAcceptedDate": null,
    // ... other user fields
  }
}
```

#### `POST /api/v1/auth/register`
For new user registration, ensure `termsAccepted` defaults to `false`:

```json
{
  "success": true,
  "token": "jwt_token",
  "data": {
    "user": {
      "_id": "user_id",
      "termsAccepted": false,
      // ... other user fields
    }
  }
}
```

#### `POST /api/v1/auth/google` and `POST /api/v1/auth/apple`
For OAuth logins, include `termsAccepted` in user response:

```json
{
  "success": true,
  "token": "jwt_token",
  "user": {
    "_id": "user_id",
    "termsAccepted": false,
    // ... other user fields
  }
}
```

## Migration for Existing Users

**Important:** All existing users should have `termsAccepted: false` by default.

If you need to migrate existing users:

```javascript
// MongoDB example
db.users.updateMany(
  { termsAccepted: { $exists: false } },
  { $set: { termsAccepted: false } }
);
```

## App Store Test Account Setup

**For Apple Review:** Apple reviewers need to see the Terms of Service screen during testing. 

**Action Required:** Set `termsAccepted: false` for the test account that will be used for App Store review.

```javascript
// Set test account to show terms screen
db.users.updateOne(
  { email: "test-account@example.com" }, // Replace with actual test account email
  { $set: { termsAccepted: false } }
);
```

This ensures Apple reviewers will see the Terms of Service screen when they log in with the test account, meeting App Store Guideline 1.2 requirements.

## Validation Logic

1. **Before Account Creation:**
   - New users can register with `termsAccepted: false`
   - They will be prompted to accept terms after registration

2. **After Terms Acceptance:**
   - Once `termsAccepted` is set to `true`, user can access the app
   - This status persists across devices and app reinstalls

3. **App Behavior:**
   - App checks `termsAccepted` field on:
     - App launch (splash screen)
     - After successful registration
     - After OAuth login
   - If `termsAccepted === false`, user cannot proceed until they accept

## Testing Checklist

- [ ] User model includes `termsAccepted` field (default: false)
- [ ] `POST /api/v1/auth/accept-terms` endpoint works correctly
- [ ] Endpoint requires authentication
- [ ] Endpoint updates user document correctly
- [ ] `GET /api/v1/auth/me` includes `termsAccepted` field
- [ ] Registration endpoints return `termsAccepted: false` for new users
- [ ] OAuth endpoints include `termsAccepted` in response
- [ ] Existing users have `termsAccepted: false` (migration if needed)

## Example Implementation (Node.js/Express)

```javascript
// Route: POST /api/v1/auth/accept-terms
router.post('/accept-terms', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const { termsAcceptedDate } = req.body;

    const user = await User.findByIdAndUpdate(
      userId,
      {
        termsAccepted: true,
        termsAcceptedDate: termsAcceptedDate || new Date()
      },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      message: 'Terms accepted successfully',
      data: {
        termsAccepted: user.termsAccepted,
        termsAcceptedDate: user.termsAcceptedDate
      }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Failed to accept terms',
      error: error.message
    });
  }
});
```

## Questions?

If you have any questions or need clarification, please refer to:
- App Store Review Guideline 1.2: User-Generated Content
- The frontend implementation in `lib/pages/authentication/screens/terms_of_service.dart`
- The API endpoint definition in `lib/service/endpoints.dart`

