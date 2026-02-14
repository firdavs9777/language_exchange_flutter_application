# 👁️ Profile Visitors Feature - Flutter Implementation

## ✅ Implementation Complete!

This feature allows users to see who has visited their profile, similar to HelloTalk. The implementation includes:

1. **Visitor Count Display** - Shows total unique visitors on profile
2. **Visitor List Screen** - Full list of visitors with details
3. **Automatic Visit Recording** - Tracks when users view profiles
4. **Clickable Navigation** - Tap visitor to view their profile

---

## 📁 Files Created/Modified

### New Files Created

#### 1. Service Layer
- **`lib/services/profile_visitor_service.dart`**
  - Handles all API calls for profile visitors
  - Methods:
    - `recordProfileVisit()` - Record a visit
    - `getProfileVisitors()` - Get visitor list with filters
    - `getMyVisitorStats()` - Get visitor statistics
    - `clearMyVisitors()` - Clear visitor history
    - `getVisitedProfiles()` - Get profiles you visited

#### 2. UI Screen
- **`lib/pages/profile/main/profile_visitors_screen.dart`**
  - Full-screen visitor list interface
  - Features:
    - Time filters (All, Today, Week, Month)
    - Shows visitor details (name, photo, location, languages)
    - Shows visit source (search, moments, chat, direct)
    - Shows visit count badge for repeat visitors
    - Pull-to-refresh support
    - Clickable cards to navigate to visitor profiles
    - Empty state when no visitors

### Modified Files

#### 1. Endpoints Configuration
- **`lib/service/endpoints.dart`**
  - Added profile visitor endpoints:
    ```dart
    static String recordProfileVisitURL(String userId)
    static String getProfileVisitorsURL(String userId)
    static const String getMyVisitorStatsURL
    static const String clearMyVisitorsURL
    static const String getVisitedProfilesURL
    ```

#### 2. Profile Page
- **`lib/pages/profile/profile_main.dart`**
  - Added visitor count card in stats section
  - Changed stats layout from 3 columns to 2x2 grid:
    - Row 1: Followers, Following
    - Row 2: Moments, **Visitors** (NEW!)
  - Visitor card shows unique visitor count
  - Tapping visitor card opens visitor list screen
  - Uses `FutureBuilder` to fetch visitor stats

#### 3. Other User's Profile
- **`lib/pages/community/single_community.dart`**
  - Added automatic visit recording when viewing profiles
  - Records visit in `_initializeUserState()`
  - Only records if viewing someone else's profile (not your own)
  - Source tracked as 'direct' (can be customized)
  - Silently fails if API call fails (doesn't disrupt UX)

---

## 🎨 UI/UX Design

### Profile Page Stats Section

```
┌─────────────────┬─────────────────┐
│   Followers     │    Following    │
│      125        │       89        │
├─────────────────┼─────────────────┤
│    Moments      │    Visitors     │
│      42         │      78         │ ← NEW!
└─────────────────┴─────────────────┘
```

### Visitor List Screen

```
┌──────────────────────────────────────┐
│  ← Profile Visitors                  │
├──────────────────────────────────────┤
│  [All] [Today] [Week] [Month]        │ ← Filters
├──────────────────────────────────────┤
│  ┌────────────────────────────────┐  │
│  │ [Photo] Alice Johnson      2m  │  │
│  │         📍 New York, USA       │  │
│  │         🌐 English → 日本語     │  │
│  │         🔍 via Search      [3] │  │ ← Visit count badge
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ [Photo] Bob Smith          1h  │  │
│  │         📍 Tokyo, Japan        │  │
│  │         🌐 日本語 → English     │  │
│  │         📸 via Moments         │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

---

## 🔄 User Flow

### Scenario 1: Viewing Your Own Visitors

1. User opens their profile
2. Sees "Visitors" card with count (e.g., "78")
3. Taps on "Visitors" card
4. Opens `ProfileVisitorsScreen`
5. Sees list of all visitors
6. Can filter by time (Today, Week, Month, All)
7. Taps on a visitor card
8. Navigates to that visitor's profile via `ProfileWrapper`

### Scenario 2: Visiting Another User's Profile

1. User A searches for User B
2. User A taps on User B's profile
3. Opens `SingleCommunity` screen
4. `_initializeUserState()` is called
5. `_recordProfileVisit()` records the visit
6. API call sent to backend with source='direct'
7. User B can now see User A in their visitor list

### Scenario 3: Navigation from Visitor List

1. User opens visitor list
2. Sees visitor cards with profile pictures
3. Taps on any visitor card
4. `_navigateToProfile()` is called
5. Opens that user's profile via `ProfileWrapper`
6. This also records a new visit (User viewing their visitor's profile)
7. Can navigate back to visitor list

---

## 📊 Data Flow

```
┌─────────────────┐
│   User Views    │
│  Other Profile  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│ single_community.dart           │
│ _recordProfileVisit()           │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ ProfileVisitorService           │
│ recordProfileVisit(userId)      │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ POST /api/v1/users/:id/         │
│      profile-visit              │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Backend Records Visit           │
│ - Visitor ID                    │
│ - Profile Owner ID              │
│ - Timestamp                     │
│ - Source (direct/search/etc)    │
│ - Device Type                   │
└─────────────────────────────────┘
```

```
┌─────────────────┐
│  User Opens     │
│  Their Profile  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│ profile_main.dart               │
│ FutureBuilder loads stats       │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ ProfileVisitorService           │
│ getMyVisitorStats()             │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ GET /api/v1/users/me/           │
│     visitor-stats               │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│ Returns:                        │
│ - totalVisits: 150              │
│ - uniqueVisitors: 78            │
│ - todayVisits: 12               │
│ - recentVisitors: [...]         │
└─────────────────────────────────┘
```

---

## 🎯 Features

### ✅ Implemented Features

1. **Visitor Count Display**
   - Shows on user's profile page
   - Shows unique visitor count
   - Real-time via API call
   - Clickable to view full list

2. **Visitor List Screen**
   - Shows all visitors with details
   - Time filters (All, Today, Week, Month)
   - Shows visitor profile picture
   - Shows visitor name and location
   - Shows visitor languages
   - Shows visit source with icon
   - Shows time ago (e.g., "2m ago")
   - Shows visit count badge for repeat visitors
   - Pull-to-refresh
   - Empty state for no visitors

3. **Automatic Visit Recording**
   - Records when viewing other profiles
   - Doesn't record own profile views
   - Tracks visit source
   - Non-blocking (doesn't affect UX if fails)

4. **Navigation**
   - Tap visitor card → Opens their profile
   - Tap visitor count → Opens visitor list
   - Back navigation works correctly
   - Profile viewing also records new visit

### 🎨 Design Details

#### Colors
- Primary: `Color(0xFF00BFA5)` (Teal)
- Visitors Icon: `Colors.orange`
- Source Icons:
  - Search: `Colors.blue`
  - Moments: `Colors.purple`
  - Chat: `Colors.green`
  - Direct: `Colors.grey`

#### Icons
- Visitor count: `Icons.visibility_outlined`
- Location: `Icons.location_on`
- Languages: `Icons.translate`
- Search source: `Icons.search`
- Moments source: `Icons.photo_library`
- Chat source: `Icons.chat`
- Direct source: `Icons.person`

#### Typography
- Visitor name: 16px, Bold, Black87
- Location/Languages: 13px, Regular, Grey600
- Source text: 12px, Medium, Source Color
- Time ago: 12px, Regular, Grey500
- Stats value: 24px, Bold, Color
- Stats label: 12px, Medium, Grey600

---

## 🧪 Testing Checklist

### Manual Testing

#### Test 1: View Visitor Count
- [ ] Open your profile page
- [ ] See "Visitors" card in stats section
- [ ] Verify count shows correctly
- [ ] Count should show "0" if no visitors
- [ ] Count should show "..." while loading

#### Test 2: Open Visitor List
- [ ] Tap on "Visitors" card
- [ ] Visitor list screen opens
- [ ] Shows correct title "Profile Visitors"
- [ ] Shows filter chips (All, Today, Week, Month)
- [ ] If no visitors, shows empty state
- [ ] If has visitors, shows visitor cards

#### Test 3: Filter Visitors
- [ ] Tap "All" filter (default selected)
- [ ] Tap "Today" filter
- [ ] List updates to show only today's visitors
- [ ] Tap "Week" filter
- [ ] List updates to show this week's visitors
- [ ] Tap "Month" filter
- [ ] List updates to show this month's visitors
- [ ] Selected filter is highlighted in teal color

#### Test 4: Visitor Card Display
- [ ] Each visitor card shows:
  - [ ] Profile picture (or default icon)
  - [ ] Name
  - [ ] Location (if available)
  - [ ] Native language and learning language
  - [ ] Visit source with icon
  - [ ] Time ago (e.g., "2m", "1h", "3d")
  - [ ] Visit count badge if visited multiple times

#### Test 5: Navigate to Visitor Profile
- [ ] Tap on any visitor card
- [ ] Opens that user's profile page
- [ ] Can view their full profile
- [ ] Can navigate back to visitor list
- [ ] Visitor list state is preserved

#### Test 6: Record Profile Visit
- [ ] Search for another user
- [ ] Open their profile
- [ ] Visit should be recorded automatically
- [ ] Check backend logs for "Profile visit recorded"
- [ ] That user should now see you in their visitor list

#### Test 7: Pull to Refresh
- [ ] On visitor list screen
- [ ] Pull down to refresh
- [ ] Loading indicator shows
- [ ] List refreshes with latest data

#### Test 8: Edge Cases
- [ ] View own profile → No visit recorded
- [ ] View profile while offline → Gracefully fails
- [ ] View profile with network error → Doesn't crash
- [ ] Empty visitor list shows appropriate message
- [ ] Very long names are truncated with ellipsis

---

## 🔧 Customization Options

### Change Visit Source Tracking

In `single_community.dart`, you can customize the source parameter:

```dart
await ProfileVisitorService.recordProfileVisit(
  userId: widget.community.id,
  source: 'search', // Change this based on context
);
```

Possible sources:
- `'search'` - From search results
- `'moments'` - From moments feed
- `'chat'` - From chat list
- `'direct'` - Direct profile view

### Change Visitor List Limit

In `profile_visitors_screen.dart`:

```dart
final result = await ProfileVisitorService.getProfileVisitors(
  userId: widget.userId,
  timeFilter: timeFilter,
  limit: 100, // Change this number
);
```

### Change Stats Display

In `profile_main.dart`, you can modify the visitor stats display:

```dart
final uniqueVisitors = stats?['uniqueVisitors'] ?? 0;
// Or use:
// final totalVisits = stats?['totalVisits'] ?? 0;
// final todayVisits = stats?['todayVisits'] ?? 0;
```

---

## 🐛 Troubleshooting

### Issue: Visitor count shows 0 but visitors exist

**Solution:**
1. Check if backend migration ran successfully
2. Verify `profileStats` fields exist in user documents
3. Check API endpoint is returning correct data
4. Verify auth token is valid

### Issue: Visit not being recorded

**Solution:**
1. Check network connection
2. Verify user is not viewing their own profile
3. Check backend logs for errors
4. Verify API endpoint URL is correct
5. Check auth token is present and valid

### Issue: Visitor list shows empty state but visitors exist

**Solution:**
1. Check API response in network logs
2. Verify data parsing in `profile_visitors_screen.dart`
3. Check if filter is too restrictive
4. Try "All" filter to see all visitors

### Issue: App crashes when opening visitor list

**Solution:**
1. Check for null safety issues
2. Verify all required fields exist in API response
3. Check console for error messages
4. Ensure `timeago` package is imported

### Issue: Profile navigation doesn't work

**Solution:**
1. Verify `ProfileWrapper` widget exists
2. Check user ID is being passed correctly
3. Verify navigation context is valid
4. Check for route conflicts

---

## 📦 Dependencies

Make sure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Existing dependencies
  flutter_riverpod: ^2.x.x
  http: ^1.x.x
  shared_preferences: ^2.x.x
  
  # Required for visitor list
  timeago: ^3.x.x  # For "time ago" formatting
  
  # Cached images (already exists)
  cached_network_image: ^3.x.x
```

If `timeago` is not in your dependencies, add it:

```bash
flutter pub add timeago
```

---

## 🚀 Next Steps

### Potential Enhancements

1. **Analytics Dashboard**
   - Show visitor trends over time
   - Graph of visits per day/week
   - Most common visit sources
   - Peak visit times

2. **Visitor Notifications**
   - Notify when someone views profile (VIP feature)
   - Daily visitor summary
   - Notify when specific users visit

3. **Privacy Controls**
   - Option to hide profile from visitor lists
   - Option to browse anonymously (VIP feature)
   - Block specific users from seeing visits

4. **Advanced Filters**
   - Filter by location
   - Filter by language
   - Filter by visit source
   - Sort options (most recent, most visits)

5. **Visit History**
   - See which profiles you've visited
   - Clear your visit history
   - Export visit data

---

## 📊 Expected Impact

### User Engagement
- ✅ Users check app more frequently to see new visitors
- ✅ Visitors are more likely to connect with profile owners
- ✅ Increases profile view reciprocity
- ✅ Creates FOMO effect (fear of missing out)

### Social Dynamics
- ✅ Profile owners can reach out to interested visitors
- ✅ Breaks the ice for conversations
- ✅ Shows who's interested in language exchange
- ✅ Encourages profile completion (to attract visitors)

### Metrics to Track
- Daily active users viewing visitor list
- Conversion rate: visitor view → follow/message
- Average time spent on visitor list screen
- Repeat visitor percentage
- Profile completion rate increase

---

## ✅ Completion Status

### Backend
- [x] ProfileVisit model created
- [x] Profile visit routes added
- [x] User model updated with profileStats
- [x] Notification service ready
- [x] Migration script created
- [x] Documentation completed

### Flutter App
- [x] Endpoints added
- [x] ProfileVisitorService created
- [x] ProfileVisitorsScreen created
- [x] Profile stats updated with visitor count
- [x] Automatic visit recording implemented
- [x] Navigation flow complete
- [x] UI/UX matches HelloTalk style
- [x] No linter errors

---

## 🎉 Feature Complete!

The profile visitor tracking feature is now fully implemented and ready for testing!

**Key Highlights:**
- ✅ Shows visitor count on profile
- ✅ Full visitor list with filters
- ✅ Automatic visit tracking
- ✅ Clickable navigation to visitor profiles
- ✅ Beautiful UI similar to HelloTalk
- ✅ Handles all edge cases
- ✅ Non-blocking, doesn't disrupt UX

**Test it out:**
1. Run the app
2. Open your profile
3. See the "Visitors" card
4. Tap to view visitor list
5. Visit other users' profiles
6. They'll see you in their visitor list!

Happy coding! 🚀

