# VIP Payment Troubleshooting Guide

## Network Error: Format Exception

### Problem
When clicking "Pay Amount", you get an error like:
```
Network error: FormatException: Unexpected character...
```

This means the response from the server is not valid JSON.

---

## Common Causes and Solutions

### 1. Backend API Not Running
**Symptoms:**
- Error message contains "Failed host lookup" or "Connection refused"
- Console shows connection timeout

**Solution:**
```bash
# Check if your backend is running
curl https://api.banatalk.com/api/v1/auth/users

# Or check locally if running on localhost
curl http://localhost:5001/api/v1/auth/users
```

**Fix:** Start your backend server.

---

### 2. Invalid User ID
**Symptoms:**
- Error shows "User ID: " (empty)
- Error contains "User not found"

**Solution:**
Check the debug info in the error dialog. If User ID is empty:

1. Make sure you're logged in properly
2. Check that the user object has an `id` field
3. Update the profile drawer to use the correct user model

**Quick Fix:**
```dart
// In profile_left_drawer.dart, verify user.id exists
buildMenuItem(context, Icons.workspace_premium, 'VIP Membership', () {
  print('User ID: ${user.id}'); // Add this debug line
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => VipPlansScreen(userId: user.id),
    ),
  );
}),
```

---

### 3. Backend Returns HTML Instead of JSON
**Symptoms:**
- Error contains "Unexpected character (at character 1)"
- Console shows HTML response like `<!DOCTYPE html>`

**Causes:**
- Wrong API endpoint URL
- Backend returning error page instead of JSON
- NGINX or proxy configuration issue

**Solution:**

Check the console output for the actual URL being called:
```
VIP Activate URL: https://api.banatalk.com/api/v1/auth/users/USER_ID/vip/activate
```

Verify this matches your backend route exactly.

**Test the endpoint directly:**
```bash
curl -X POST https://api.banatalk.com/api/v1/auth/users/YOUR_USER_ID/vip/activate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"plan": "monthly", "paymentMethod": "card"}'
```

---

### 4. CORS Issue (Web Only)
**Symptoms:**
- Works on mobile but fails on web
- Console shows CORS error

**Solution:**
Add CORS headers to your backend:
```javascript
// In your backend (Express.js example)
app.use(cors({
  origin: '*', // or your specific frontend URL
  credentials: true
}));
```

---

### 5. Missing or Invalid Token
**Symptoms:**
- Error: "Authentication required"
- Status code: 401

**Solution:**
Check if the token is stored properly:
```dart
// Add debug logging
final token = await _getToken();
print('Token: $token');
```

If token is null, user needs to log in again.

---

## Debug Mode Setup

### Enable Detailed Logging

The code already has debug logging. To see it:

1. **Run the app in debug mode:**
```bash
flutter run
```

2. **Watch the console when clicking "Pay Amount"**

You should see:
```
VIP Activate URL: https://...
VIP Activate Request: plan=monthly, payment=card
VIP Activate Response Status: 200
VIP Activate Response Body: {...}
```

3. **Check for errors:**
- If URL is wrong → Update endpoints.dart
- If status is 404 → Backend route not found
- If status is 500 → Backend error
- If response body is HTML → Backend configuration issue

---

## Testing Without Backend

If you want to test the UI without a working backend, you can mock the response:

```dart
// In lib/services/vip_service.dart
static Future<Map<String, dynamic>> activateVip({
  required String userId,
  required VipPlan plan,
  required String paymentMethod,
}) async {
  // MOCK RESPONSE FOR TESTING
  await Future.delayed(const Duration(seconds: 2));

  return {
    'success': true,
    'data': {
      'user': {
        'userMode': 'vip',
        'vipSubscription': {
          '_id': 'sub_test_123',
          'plan': plan.name,
          'startDate': DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(Duration(days: 30)).toIso8601String(),
          'status': 'active',
          'amount': plan.price,
          'paymentMethod': paymentMethod,
        },
      },
    },
  };
}
```

---

## Checklist for Error Resolution

When you encounter the error, check:

- [ ] Is the backend server running?
- [ ] Is the API URL correct in endpoints.dart?
- [ ] Does the user have a valid ID?
- [ ] Is the user logged in with a valid token?
- [ ] Can you access the API endpoint with curl?
- [ ] Is the backend returning JSON (not HTML)?
- [ ] Check the console logs for detailed error info
- [ ] Check the error dialog for User ID, Plan, and Payment method

---

## Getting Help

When reporting issues, provide:

1. **Console output** - Copy the logs from "VIP Activate URL" to the error
2. **Error dialog info** - Screenshot or copy the debug info
3. **Backend response** - If possible, test with curl and include response
4. **Environment** - iOS/Android/Web, Flutter version, backend URL

Example:
```
Environment: Android, Flutter 3.1.4
Backend: https://api.banatalk.com/api/v1/
Console Output:
  VIP Activate URL: https://api.banatalk.com/api/v1/auth/users/123/vip/activate
  VIP Activate Response Status: 500
  VIP Activate Response Body: <!DOCTYPE html>...
Error: Network error: FormatException: Unexpected character
```

---

## Quick Fixes by Error Type

### "User ID not found"
→ User needs to be logged in, check authentication state

### "Failed host lookup"
→ No internet or backend server down

### "Connection refused"
→ Backend not running or wrong URL

### "FormatException: Unexpected character"
→ Backend returning HTML instead of JSON - check endpoint URL

### "Invalid response format"
→ Backend JSON structure doesn't match expected format

### "Authentication required"
→ Token missing or expired, user needs to log in again

### "Server error: 500"
→ Backend error, check backend logs

### "Failed to activate VIP subscription"
→ Backend processed request but rejected it, check backend validation

---

## Temporary Workaround

While debugging, you can bypass the payment and manually set VIP status:

1. Use the admin endpoint to change user mode:
```bash
curl -X PUT https://api.banatalk.com/api/v1/auth/users/USER_ID/mode \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -d '{"mode": "vip"}'
```

2. Or create a test button in your app:
```dart
// Add to payment screen for testing
ElevatedButton(
  onPressed: () async {
    // Mock success for testing
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Mode'),
        content: Text('Simulating VIP activation'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  },
  child: Text('TEST MODE - Skip Payment'),
),
```

---

## Need More Help?

Check the logs at these locations:
- **Frontend logs:** Flutter console when running `flutter run`
- **Backend logs:** Your backend server console
- **Network logs:** Use Charles Proxy or similar to inspect HTTP traffic
