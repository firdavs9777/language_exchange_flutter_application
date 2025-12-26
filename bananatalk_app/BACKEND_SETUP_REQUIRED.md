# 🔧 Backend Setup Required for Profile Visitors

## ⚠️ Current Status

The **Profile Visitors feature** is fully implemented in Flutter, but requires backend API endpoints to function.

**Current Behavior:**
- ✅ Flutter code is complete and working
- ⚠️ Visitor count shows "0" (API not available)
- ⚠️ Clicking visitor count shows message: "Visitor tracking feature is not available yet"
- ✅ App doesn't crash or show errors
- ✅ Graceful fallback to 0 visitors

---

## 🎯 What's Needed

### Backend Implementation Required:

The backend needs to have the Profile Visitors API endpoints deployed. According to your earlier summary, you mentioned these were already implemented in the backend. You need to:

1. **Deploy the backend code** with visitor tracking endpoints
2. **Run the migration** to add required fields
3. **Restart the server**
4. **Verify endpoints are accessible**

---

## 📋 Backend Checklist

### Step 1: Verify Backend Files Exist

Check if these files exist in your backend:

```
backend/
├── models/
│   └── ProfileVisit.js          ✅ Should exist
├── controllers/
│   └── profileVisits.js         ✅ Should exist
├── routes/
│   └── users.js                 ✅ Should be updated
├── services/
│   └── notificationService.js   ✅ Should be updated
└── migrations/
    └── addProfileVisitorFields.js ✅ Should exist
```

### Step 2: Deploy Backend

```bash
# SSH into your server
ssh your-server

# Navigate to backend directory
cd /path/to/backend

# Pull latest code (if using git)
git pull origin main

# Or upload files manually
scp -r * your-server:/path/to/backend/
```

### Step 3: Run Migration

```bash
# On your production server
npm run migrate:profile-visitors
```

**Expected Output:**
```
✅ Connected to MongoDB
📊 Total users in database: X
✅ Successfully updated: X users
📊 Verification Results:
  - Users with profileStats: X/X
  - Users with followerMoments setting: X/X
🎉 Migration completed successfully!
```

### Step 4: Restart Server

```bash
# If using PM2
pm2 restart language-app

# Or if using npm directly
npm run start
```

### Step 5: Verify Endpoints

Test the endpoints:

```bash
# Test visitor stats endpoint
curl -X GET \
  https://api.banatalk.com/api/v1/users/me/visitor-stats \
  -H 'Authorization: Bearer YOUR_TOKEN'

# Expected response:
{
  "success": true,
  "data": {
    "stats": {
      "totalVisits": 0,
      "uniqueVisitors": 0,
      "todayVisits": 0,
      "recentVisitors": []
    }
  }
}
```

---

## 🔍 Troubleshooting

### Issue: Endpoints Return HTML

**Symptoms:**
- Flutter shows "0" visitors
- Console shows: `⚠️ Visitor stats API not available`

**Cause:** Backend endpoints not deployed or incorrect URL

**Solution:**
1. Verify backend code is deployed
2. Check API base URL in Flutter: `lib/service/endpoints.dart`
3. Currently set to: `https://api.banatalk.com/api/v1/`
4. Verify this URL is correct

### Issue: 404 Not Found

**Cause:** Routes not registered in Express app

**Solution:**
Check `routes/users.js` has these routes:
```javascript
router.post('/users/:userId/profile-visit', ...)
router.get('/users/:userId/visitors', ...)
router.get('/users/me/visitor-stats', ...)
router.delete('/users/me/visitors', ...)
```

### Issue: MongoDB Connection Error

**Cause:** Migration can't connect to database

**Solution:**
1. Check MongoDB connection string
2. Verify database is accessible
3. Check network/firewall rules

---

## 📊 API Endpoints Required

These endpoints must be available:

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | `/api/v1/users/:userId/profile-visit` | Record a visit |
| GET | `/api/v1/users/:userId/visitors` | Get visitor list |
| GET | `/api/v1/users/me/visitor-stats` | Get visitor stats |
| DELETE | `/api/v1/users/me/visitors` | Clear visit history |
| GET | `/api/v1/users/me/visited-profiles` | Get visited profiles |

---

## 🧪 Testing Backend

### Test 1: Record Visit
```bash
curl -X POST \
  https://api.banatalk.com/api/v1/users/USER_ID/profile-visit \
  -H 'Authorization: Bearer YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "source": "direct",
    "deviceType": "mobile"
  }'
```

**Expected:** 
```json
{
  "success": true,
  "message": "Profile visit recorded successfully"
}
```

### Test 2: Get Visitor Stats
```bash
curl -X GET \
  https://api.banatalk.com/api/v1/users/me/visitor-stats \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

**Expected:**
```json
{
  "success": true,
  "data": {
    "stats": {
      "totalVisits": 1,
      "uniqueVisitors": 1,
      "todayVisits": 1
    }
  }
}
```

### Test 3: Get Visitor List
```bash
curl -X GET \
  https://api.banatalk.com/api/v1/users/USER_ID/visitors \
  -H 'Authorization: Bearer YOUR_TOKEN'
```

**Expected:**
```json
{
  "success": true,
  "data": {
    "visitors": [
      {
        "user": { /* user object */ },
        "lastVisit": "2024-01-15T10:30:00Z",
        "visitCount": 1,
        "source": "direct"
      }
    ],
    "pagination": { /* pagination */ }
  }
}
```

---

## 🚀 Once Backend is Ready

When the backend is deployed and working:

1. **Hot restart the Flutter app** (or fully restart)
2. **Open your profile**
3. **You should see:**
   - Visitor count loading as "..."
   - Then showing actual count (initially 0)
4. **View another user's profile**
   - Visit will be recorded
5. **They should see:**
   - Their visitor count increase
   - You in their visitor list

---

## 📝 Backend Implementation Reference

If the backend code is missing, refer to the summary document you showed earlier:

**File:** Your earlier message mentioned:
```
# 🎉 New Features Implemented - Summary

## ✅ What Was Built

Three major features have been successfully implemented:

### 1. 👁️ Profile Visitor Tracking
...

## 📦 Files Created

### Models
- ✅ `models/ProfileVisit.js` - Track profile visits
```

This indicates the backend code should already exist. You just need to:
1. Deploy it
2. Run migrations
3. Restart server

---

## 🔄 Quick Fix Summary

**Current State:**
- ✅ Flutter app complete
- ⚠️ Shows "0" visitors (backend not ready)
- ✅ No crashes or errors
- ✅ Graceful fallback

**To Enable Feature:**
1. Deploy backend with visitor endpoints
2. Run: `npm run migrate:profile-visitors`
3. Restart: `pm2 restart language-app`
4. Verify: Test endpoints with curl
5. Test: Hot restart Flutter app

**Time Required:** ~10 minutes (if backend code exists)

---

## 💡 Development vs Production

### Development (localhost)

If testing locally, update Flutter endpoints:

```dart
// In lib/service/endpoints.dart
static String baseURL = "http://localhost:5003/api/v1/";
// Or for physical device:
static String baseURL = "http://192.168.1.100:5003/api/v1/";
```

### Production

Currently set to:
```dart
static String baseURL = "https://api.banatalk.com/api/v1/";
```

Make sure your backend is deployed there.

---

## ✅ Verification Checklist

Before testing in Flutter:

- [ ] Backend code deployed
- [ ] Migration completed successfully
- [ ] Server restarted
- [ ] Endpoints return JSON (not HTML)
- [ ] Auth token works
- [ ] Test with curl successful

After backend is ready:

- [ ] Flutter app shows real visitor counts
- [ ] Visiting profile records visit
- [ ] Visitor list shows visitors
- [ ] Filters work
- [ ] Navigation works

---

## 📞 Need Help?

### Check Server Logs

```bash
pm2 logs language-app --lines 100
```

Look for:
- ✅ "Profile visit recorded"
- ✅ "MongoDB Connected"
- ❌ Any error messages

### Check Database

```javascript
// In MongoDB
use your_database;

// Check if collections exist
db.getCollectionNames();
// Should include: 'profilevisits'

// Check if user has profileStats
db.users.findOne({}, { profileStats: 1 });
// Should show: { profileStats: { totalVisits: 0, ... } }

// Check profile visits
db.profilevisits.find().limit(5);
```

---

## 🎉 Summary

**The Flutter app is fully ready!** It just needs the backend APIs to be deployed.

Once the backend is live:
- Visitor count will show real numbers
- Visit recording will work automatically
- Visitor list will populate
- Feature will be 100% functional

**Current Flutter behavior is intentional** - it shows "0" and gracefully handles the missing backend without crashing.

Deploy the backend and you're good to go! 🚀

