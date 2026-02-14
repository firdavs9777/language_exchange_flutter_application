# Backend API Requirements for BananaTalk

This document outlines the API endpoints and features needed by the Flutter frontend.

---

## 1. LESSON COMPLETION ENDPOINT (CRITICAL)

### Current Issue
The `POST /api/v1/learning/lessons/{id}/submit` returns 404. We're using `POST /api/v1/lessons/{id}/complete` which works but returns `score:0, correctAnswers:0, totalQuestions:0` even when answers are sent.

### Required Fix
The backend should:
1. Parse the `answers` array from the request body
2. Calculate correct answers based on `exerciseIndex` and `answer` fields
3. Return accurate `score`, `correctAnswers`, `totalQuestions`

### Request Body
```json
POST /api/v1/lessons/{lessonId}/complete
{
  "answers": [
    {
      "exerciseIndex": 0,
      "answer": "697ccd57ccda5bd5982a27f3",  // Option ID for multiple_choice
      "isCorrect": true
    },
    {
      "exerciseIndex": 1,
      "answer": "I have lunch.",  // Text for fill_blank/translation
      "isCorrect": false
    },
    {
      "exerciseIndex": 2,
      "answer": "Wake up:Despertarse|Brush teeth:Cepillarse los dientes",  // Matching format
      "isCorrect": true
    },
    {
      "exerciseIndex": 3,
      "answer": "item1|item2|item3",  // Ordering format
      "isCorrect": true
    }
  ],
  "timeSpent": 120
}
```

### Expected Response
```json
{
  "success": true,
  "data": {
    "lessonId": "697ccd57ccda5bd5982a27ed",
    "score": 75,
    "correctAnswers": 3,
    "totalQuestions": 4,
    "isPerfect": false,
    "xpEarned": 25,
    "isFirstCompletion": true,
    "progress": {
      "totalXp": 250,
      "level": 3,
      "lessonsCompleted": 12
    }
  }
}
```

---

## 2. COMMUNITY/NEARBY USERS ENDPOINT

### Current Issue
No dedicated nearby endpoint. All users are fetched and filtered client-side, which is inefficient.

### Required Endpoint
```
GET /api/v1/community/nearby
```

### Query Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| latitude | number | User's current latitude |
| longitude | number | User's current longitude |
| radius | number | Search radius in kilometers (default: 50) |
| limit | number | Max users to return (default: 50) |
| offset | number | Pagination offset |
| language | string | Filter by language to learn |
| minAge | number | Minimum age filter |
| maxAge | number | Maximum age filter |
| gender | string | Gender filter (male/female/other) |
| onlineOnly | boolean | Only show online users |

### Response
```json
{
  "success": true,
  "data": [
    {
      "_id": "user123",
      "name": "John",
      "imageUrls": ["https://..."],
      "location": {
        "type": "Point",
        "coordinates": [127.0276, 37.4979],
        "city": "Seoul",
        "country": "South Korea"
      },
      "distance": 2.5,  // <-- IMPORTANT: Distance in km from requester
      "native_language": "English",
      "language_to_learn": "Korean",
      "isOnline": true,
      "lastSeen": "2024-01-15T10:30:00Z"
    }
  ],
  "pagination": {
    "total": 150,
    "limit": 50,
    "offset": 0
  }
}
```

### Backend Implementation
Use MongoDB's `$geoNear` aggregation for efficient distance-based queries:

```javascript
db.users.aggregate([
  {
    $geoNear: {
      near: { type: "Point", coordinates: [longitude, latitude] },
      distanceField: "distance",
      maxDistance: radius * 1000, // Convert km to meters
      spherical: true
    }
  },
  { $match: { /* filters */ } },
  { $skip: offset },
  { $limit: limit }
])
```

---

## 3. WAVE FEATURE ENDPOINT

### Current Issue
Wave feature is UI-only (shows snackbar). No backend tracking.

### Required Endpoints

#### Send Wave
```
POST /api/v1/community/wave
```
```json
{
  "targetUserId": "user456"
}
```

Response:
```json
{
  "success": true,
  "data": {
    "waveId": "wave123",
    "isMutual": false,  // True if both users waved at each other
    "message": "Wave sent!"
  }
}
```

#### Get Waves Received
```
GET /api/v1/community/waves
```
Response:
```json
{
  "success": true,
  "data": {
    "waves": [
      {
        "waveId": "wave123",
        "from": { "_id": "user456", "name": "Jane", "imageUrls": ["..."] },
        "createdAt": "2024-01-15T10:30:00Z",
        "isRead": false
      }
    ],
    "unreadCount": 5
  }
}
```

---

## 4. TOPICS ENDPOINT

### Current Issue
Topics are hardcoded in the app. No dynamic topic loading from backend.

### Required Endpoint
```
GET /api/v1/community/topics
```

Response:
```json
{
  "success": true,
  "data": [
    {
      "id": "topic_travel",
      "name": "Travel",
      "icon": "airplane",
      "category": "lifestyle",
      "userCount": 1234
    },
    {
      "id": "topic_music",
      "name": "Music",
      "icon": "music_note",
      "category": "entertainment",
      "userCount": 5678
    }
  ]
}
```

### Get Users by Topic
```
GET /api/v1/community/topics/{topicId}/users
```

---

## 5. VOICE ROOMS ENDPOINTS

### Required Endpoints

#### List Active Rooms
```
GET /api/v1/voicerooms
```

#### Create Room
```
POST /api/v1/voicerooms
```
```json
{
  "title": "English Practice",
  "topic": "language_exchange",
  "language": "en",
  "maxParticipants": 8
}
```

#### Join Room
```
POST /api/v1/voicerooms/{roomId}/join
```

#### Leave Room
```
POST /api/v1/voicerooms/{roomId}/leave
```

#### WebSocket Events (for voice)
- `room:join` - User joined room
- `room:leave` - User left room
- `room:speaking` - User started/stopped speaking
- `room:mute` - User muted/unmuted

---

## 6. SOCKET.IO IMPROVEMENTS

### Current Issues
1. Server disconnects without reason logged
2. No token refresh notification to client
3. Multiple "io server disconnect" events

### Required Socket Events

#### Token Expiring Soon
```javascript
socket.emit('tokenExpiring', {
  expiresIn: 300 // seconds until expiry
});
```
Client will refresh token and call `refreshConnection()`.

#### Connection Verified
```javascript
socket.emit('connectionVerified', {
  userId: 'user123',
  connectedAt: '2024-01-15T10:30:00Z'
});
```

#### Graceful Disconnect Reason
```javascript
socket.emit('disconnect', {
  reason: 'token_expired' | 'maintenance' | 'duplicate_session' | 'user_blocked'
});
```

---

## 7. USER PROFILE ENHANCEMENTS

### Current Model Additions Needed

Add to User schema:
```javascript
{
  topics: [String],           // User's interests (topic IDs)
  languageLevel: String,      // A1, A2, B1, B2, C1, C2
  responseRate: Number,       // 0-100 percentage
  responseTime: String,       // "within 1 hour", "within 1 day"
  verificationStatus: String, // unverified, photo_verified, video_verified
  compatibilityScore: Number  // Calculated match score with viewer
}
```

### Update Profile Endpoint
```
PUT /api/v1/auth/users/{userId}
```
Should accept:
```json
{
  "topics": ["topic_travel", "topic_music"],
  "languageLevel": "B2"
}
```

---

## 8. PAGINATION FOR ALL LIST ENDPOINTS

All list endpoints should support:
- `limit` - Items per page
- `offset` or `page` - Pagination offset
- Return `pagination` object in response:

```json
{
  "pagination": {
    "total": 500,
    "limit": 50,
    "offset": 0,
    "hasMore": true
  }
}
```

Affected endpoints:
- `GET /api/v1/auth/users` (Community list)
- `GET /api/v1/messages/user/{id}` (Chat list)
- `GET /api/v1/lessons` (Lessons list)
- `GET /api/v1/vocabulary` (Vocabulary list)

---

## 9. MATCHING EXERCISE DATA FORMAT

### Current Issue
Matching exercises use `text`/`matchWith` in options array. This works but is inconsistent.

### Recommended Standard Format
```json
{
  "type": "matching",
  "question": "Match the words with their translations:",
  "matchingPairs": [
    { "left": "Wake up", "right": "Despertarse" },
    { "left": "Brush teeth", "right": "Cepillarse los dientes" }
  ]
}
```

Currently the app handles both formats, but `matchingPairs` array is preferred.

---

## 10. ORDERING EXERCISE DATA FORMAT

### Current Issue
`scrambledItems` and `correctOrder` are null. Only `correctAnswer` is provided as array string.

### Recommended Standard Format
```json
{
  "type": "ordering",
  "question": "Put the words in order:",
  "scrambledItems": ["word2", "word1", "word3"],
  "correctOrder": ["word1", "word2", "word3"]
}
```

---

## Priority Order

1. **HIGH**: Fix lesson completion to calculate scores correctly
2. **HIGH**: Add nearby users endpoint with distance
3. **MEDIUM**: Add wave tracking endpoints
4. **MEDIUM**: Add topics API
5. **MEDIUM**: Fix socket disconnect reasons
6. **LOW**: Voice rooms endpoints
7. **LOW**: Pagination for all lists

---

## Questions for Backend Team

1. Is GeoJSON indexing enabled on the users collection for location queries?
2. What's the WebSocket server implementation (Socket.IO version)?
3. Is there a token refresh endpoint or mechanism?
4. What authentication provider is used for tokens (JWT)?
5. Is there a rate limit for API calls?

---

*Generated by Claude Code - Please update this document as APIs are implemented.*
