# VIP and Visitor Mode API Reference

## Base URL
```
https://api.banatalk.com/api/v1/
```

## Authentication
All endpoints require authentication via Bearer token in the Authorization header:
```
Authorization: Bearer <your_token>
```

## Endpoints

### 1. Activate VIP Subscription
Upgrade a user to VIP status with a selected plan.

**Endpoint:** `POST /auth/users/:userId/vip/activate`

**Request Body:**
```json
{
  "plan": "monthly" | "quarterly" | "yearly",
  "paymentMethod": "card" | "paypal" | "google_pay" | "apple_pay"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "VIP subscription activated successfully",
  "user": {
    "userMode": "vip",
    "vipSubscription": {
      "_id": "sub_123",
      "plan": "monthly",
      "startDate": "2025-01-01T00:00:00.000Z",
      "endDate": "2025-02-01T00:00:00.000Z",
      "status": "active",
      "amount": 9.99,
      "paymentMethod": "card"
    },
    "vipFeatures": {
      "unlimitedMessages": true,
      "unlimitedProfileViews": true,
      "prioritySupport": true,
      "advancedSearch": true,
      "profileBoost": true,
      "adFree": true
    }
  }
}
```

**Flutter Usage:**
```dart
final result = await VipService.activateVip(
  userId: 'user123',
  plan: VipPlan.monthly,
  paymentMethod: 'card',
);

if (result['success']) {
  print('VIP activated!');
}
```

---

### 2. Deactivate VIP Subscription
Cancel an active VIP subscription.

**Endpoint:** `POST /auth/users/:userId/vip/deactivate`

**Request Body:** None

**Response (200 OK):**
```json
{
  "success": true,
  "message": "VIP subscription cancelled successfully",
  "user": {
    "userMode": "regular",
    "vipSubscription": null,
    "vipFeatures": null
  }
}
```

**Flutter Usage:**
```dart
final result = await VipService.deactivateVip(userId: 'user123');

if (result['success']) {
  print('VIP cancelled');
}
```

---

### 3. Get VIP Status
Retrieve the current VIP subscription status and features.

**Endpoint:** `GET /auth/users/:userId/vip/status`

**Response (200 OK):**
```json
{
  "isVip": true,
  "vipSubscription": {
    "_id": "sub_123",
    "plan": "monthly",
    "startDate": "2025-01-01T00:00:00.000Z",
    "endDate": "2025-02-01T00:00:00.000Z",
    "status": "active",
    "amount": 9.99,
    "paymentMethod": "card"
  },
  "vipFeatures": {
    "unlimitedMessages": true,
    "unlimitedProfileViews": true,
    "prioritySupport": true,
    "advancedSearch": true,
    "profileBoost": true,
    "adFree": true
  }
}
```

**Flutter Usage:**
```dart
final result = await VipService.getVipStatus(userId: 'user123');

if (result['success']) {
  VipSubscription? subscription = result['vipSubscription'];
  VipFeatures? features = result['vipFeatures'];
}
```

---

### 4. Upgrade Visitor to Regular User
Convert a visitor account to a full registered user.

**Endpoint:** `POST /auth/users/:userId/upgrade-visitor`

**Request Body:** None

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Visitor upgraded to regular user successfully",
  "user": {
    "userMode": "regular",
    "visitorLimitations": null
  }
}
```

**Flutter Usage:**
```dart
final result = await VipService.upgradeVisitor(userId: 'user123');

if (result['success']) {
  print('Upgraded to regular user!');
}
```

---

### 5. Get Visitor Limits
Retrieve current usage and remaining limits for a visitor.

**Endpoint:** `GET /auth/users/:userId/visitor/limits`

**Response (200 OK):**
```json
{
  "limitations": {
    "dailyMessageLimit": 5,
    "dailyProfileViewLimit": 10,
    "messagesSentToday": 3,
    "profileViewsToday": 7,
    "lastResetDate": "2025-01-01T00:00:00.000Z"
  },
  "remainingMessages": 2,
  "remainingProfileViews": 3
}
```

**Flutter Usage:**
```dart
final result = await VipService.getVisitorLimits(userId: 'user123');

if (result['success']) {
  VisitorLimitations? limitations = result['visitorLimitations'];
  print('Remaining messages: ${limitations?.remainingMessages}');
}
```

---

### 6. Change User Mode (Admin Only)
Change a user's mode between visitor, regular, and VIP.

**Endpoint:** `PUT /auth/users/:userId/mode`

**Request Body:**
```json
{
  "mode": "visitor" | "regular" | "vip"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "User mode updated successfully",
  "user": {
    "userMode": "vip"
  }
}
```

**Flutter Usage:**
```dart
final result = await VipService.changeUserMode(
  userId: 'user123',
  newMode: UserMode.vip,
);

if (result['success']) {
  print('User mode changed');
}
```

---

## Error Responses

### 400 Bad Request
```json
{
  "success": false,
  "message": "Invalid plan type"
}
```

### 401 Unauthorized
```json
{
  "success": false,
  "message": "Authentication required"
}
```

### 403 Forbidden
```json
{
  "success": false,
  "message": "Admin access required"
}
```

### 404 Not Found
```json
{
  "success": false,
  "message": "User not found"
}
```

### 500 Internal Server Error
```json
{
  "success": false,
  "message": "Internal server error"
}
```

---

## User Object Structure

The user object returned from the backend includes these VIP-related fields:

```json
{
  "_id": "user123",
  "name": "John Doe",
  "email": "john@example.com",
  "userMode": "visitor" | "regular" | "vip",

  // VIP fields (only if userMode === 'vip')
  "vipSubscription": {
    "_id": "sub_123",
    "plan": "monthly",
    "startDate": "2025-01-01T00:00:00.000Z",
    "endDate": "2025-02-01T00:00:00.000Z",
    "status": "active",
    "amount": 9.99,
    "paymentMethod": "card"
  },
  "vipFeatures": {
    "unlimitedMessages": true,
    "unlimitedProfileViews": true,
    "prioritySupport": true,
    "advancedSearch": true,
    "profileBoost": true,
    "adFree": true
  },

  // Visitor fields (only if userMode === 'visitor')
  "visitorLimitations": {
    "dailyMessageLimit": 5,
    "dailyProfileViewLimit": 10,
    "messagesSentToday": 3,
    "profileViewsToday": 7,
    "lastResetDate": "2025-01-01T00:00:00.000Z"
  }
}
```

---

## VIP Plans Pricing

### Monthly Plan
- **Price:** $9.99/month
- **Duration:** 30 days
- **Savings:** Base price

### Quarterly Plan
- **Price:** $24.99/3 months
- **Duration:** 90 days
- **Savings:** 17% off (compared to 3 monthly payments)

### Yearly Plan
- **Price:** $79.99/year
- **Duration:** 365 days
- **Savings:** 33% off (compared to 12 monthly payments)

---

## VIP Features

All VIP plans include:

1. **Unlimited Messages** - Send unlimited messages per day
2. **Unlimited Profile Views** - View unlimited profiles per day
3. **Priority Support** - Get faster responses from support team
4. **Advanced Search** - Access advanced search filters
5. **Profile Boost** - Increased visibility in search results
6. **Ad-Free Experience** - No advertisements

---

## Visitor Limitations

Default limits for visitor accounts:

- **Daily Messages:** 5 messages/day
- **Daily Profile Views:** 10 profiles/day
- **Resets:** Daily at midnight UTC

When limits are reached, visitors are prompted to:
1. Create a free account (higher limits)
2. Upgrade to VIP (unlimited access)

---

## Integration Flow

### New User Flow
```
1. User visits app → userMode: 'visitor'
2. User hits limit → Show upgrade dialog
3. User signs up → userMode: 'regular'
4. User upgrades to VIP → userMode: 'vip'
```

### Payment Flow
```
1. User selects VIP plan
2. User chooses payment method
3. Frontend calls payment provider
4. Payment succeeds
5. Frontend calls /vip/activate endpoint
6. Backend creates subscription
7. User becomes VIP
```

### Subscription Management Flow
```
1. VIP user views subscription status
2. User can see:
   - Active plan
   - Renewal date
   - Active features
3. User can cancel subscription
4. User reverts to regular mode
```

---

## Testing Endpoints

You can test these endpoints using curl:

```bash
# Activate VIP
curl -X POST https://api.banatalk.com/api/v1/auth/users/USER_ID/vip/activate \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"plan": "monthly", "paymentMethod": "card"}'

# Get VIP Status
curl -X GET https://api.banatalk.com/api/v1/auth/users/USER_ID/vip/status \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get Visitor Limits
curl -X GET https://api.banatalk.com/api/v1/auth/users/USER_ID/visitor/limits \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Notes

1. All timestamps are in ISO 8601 format (UTC)
2. User tokens are stored in SharedPreferences and automatically included in requests
3. Subscription renewals are handled automatically by the backend
4. Visitor limits reset daily at midnight UTC
5. Failed payments result in subscription status change to 'expired'
