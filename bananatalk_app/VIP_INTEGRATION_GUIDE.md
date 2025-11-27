# VIP and Visitor Mode Integration Guide

This guide explains how to integrate the VIP subscription and visitor management features into your BananaTalk app.

## Overview

The app now supports three user modes:
- **Visitor**: Limited daily access (5 messages, 10 profile views)
- **Regular**: Standard user features
- **VIP**: Premium features with unlimited access

## Files Created

### Models
- `lib/models/vip_subscription.dart` - VIP subscription data models
  - `VipSubscription` - Subscription details
  - `VipFeatures` - Feature flags for VIP users
  - `VisitorLimitations` - Daily usage limits for visitors
  - `UserMode` - Enum for user modes
  - `VipPlan` - Enum for subscription plans

### Services
- `lib/services/vip_service.dart` - API service for VIP operations
  - `activateVip()` - Activate VIP subscription
  - `deactivateVip()` - Cancel VIP subscription
  - `getVipStatus()` - Get VIP subscription status
  - `upgradeVisitor()` - Upgrade visitor to regular user
  - `getVisitorLimits()` - Get visitor usage limits
  - `changeUserMode()` - Admin function to change user mode

### UI Screens
- `lib/pages/vip/vip_plans_screen.dart` - VIP subscription plans UI
- `lib/pages/vip/vip_payment_screen.dart` - Payment processing UI
- `lib/pages/vip/vip_status_screen.dart` - VIP subscription status
- `lib/pages/vip/visitor_upgrade_screen.dart` - Visitor upgrade flow

### Widgets
- `lib/widgets/visitor_limit_dialog.dart` - Dialog shown when limits are reached
- `lib/widgets/visitor_usage_indicator.dart` - Usage indicator for visitors
  - `VisitorUsageIndicator` - Shows remaining messages/views
  - `VisitorBadge` - Displays "Visitor" badge
  - `VipBadge` - Displays "VIP" badge

### Utilities
- `lib/utils/feature_gate.dart` - Feature gating logic
  - `FeatureGate.canSendMessage()` - Check message permission
  - `FeatureGate.canViewProfile()` - Check profile view permission
  - `FeatureGate.hasVipFeature()` - Check VIP feature access
  - `FeatureGate.showLimitReachedDialog()` - Show limit dialog
  - `UserFeatureExtensions` - Extension methods for User model

### Updated Files
- `lib/providers/provider_models/users_model.dart` - Added VIP/visitor fields
- `lib/pages/profile/main/profile_left_drawer.dart` - Added VIP menu item

## Integration Steps

### 1. Update User State Management

When fetching user data from your backend, parse the new fields:

```dart
// Example in your auth provider or user provider
User parseUserFromJson(Map<String, dynamic> json) {
  return User(
    // Existing fields...
    name: json['name'],
    email: json['email'],
    // ... other fields

    // New fields
    userMode: UserMode.fromString(json['userMode'] ?? 'regular'),
    vipSubscription: json['vipSubscription'] != null
      ? VipSubscription.fromJson(json['vipSubscription'])
      : null,
    vipFeatures: json['vipFeatures'] != null
      ? VipFeatures.fromJson(json['vipFeatures'])
      : null,
    visitorLimitations: json['visitorLimitations'] != null
      ? VisitorLimitations.fromJson(json['visitorLimitations'])
      : null,
  );
}
```

### 2. Add Feature Gates to Your Features

#### Protect Message Sending

```dart
import 'package:bananatalk_app/utils/feature_gate.dart';
import 'package:bananatalk_app/widgets/visitor_limit_dialog.dart';

// In your message sending function
Future<void> sendMessage(User currentUser, String message) async {
  // Check if user can send message
  if (!FeatureGate.canSendMessage(currentUser)) {
    // Show limit reached dialog
    await FeatureGate.showLimitReachedDialog(
      context: context,
      user: currentUser,
      limitType: 'message',
    );
    return;
  }

  // Continue with sending message
  // ...
}
```

#### Protect Profile Viewing

```dart
// In your profile view function
Future<void> viewProfile(User currentUser, String profileId) async {
  // Check if user can view profile
  if (!FeatureGate.canViewProfile(currentUser)) {
    await FeatureGate.showLimitReachedDialog(
      context: context,
      user: currentUser,
      limitType: 'profile',
    );
    return;
  }

  // Continue with viewing profile
  // ...
}
```

#### Hide VIP-Only Features

```dart
// Example: Hide advanced search for non-VIP users
if (currentUser.isVip && FeatureGate.hasVipFeature(currentUser, 'advancedSearch')) {
  // Show advanced search UI
  AdvancedSearchWidget();
} else {
  // Show basic search or locked message
  Text('Advanced search is VIP only');
}
```

### 3. Display User Mode and Usage

#### Show User Badge

```dart
import 'package:bananatalk_app/utils/feature_gate.dart';

// In your profile header or app bar
Widget buildUserHeader(User user) {
  return Row(
    children: [
      Text(user.name),
      SizedBox(width: 8),
      user.modeBadge, // Extension method from feature_gate.dart
    ],
  );
}
```

#### Show Usage Indicator for Visitors

```dart
import 'package:bananatalk_app/widgets/visitor_usage_indicator.dart';

// In your main screen or drawer
Widget buildContent(User user) {
  return Column(
    children: [
      // Show usage indicator for visitors
      if (user.isVisitor && user.visitorLimitations != null)
        VisitorUsageIndicator(
          limitations: user.visitorLimitations!,
          compact: false, // Set to true for compact view
        ),

      // Rest of your content
      // ...
    ],
  );
}
```

### 4. Add VIP Subscription Flow

The VIP menu item has already been added to the profile drawer. Users can:

1. Click "VIP Membership" in the profile drawer
2. View plans and pricing
3. Select a plan (Monthly, Quarterly, or Yearly)
4. Choose payment method
5. Complete payment

### 5. Handle Visitor Upgrade Flow

```dart
// When a visitor hits their limit
if (user.isVisitor && !FeatureGate.canSendMessage(user)) {
  // The dialog will automatically show upgrade options
  await VisitorLimitDialog.show(
    context: context,
    userId: user.id,
    limitType: 'message',
    limitations: user.visitorLimitations!,
  );
}
```

## API Integration

Make sure your backend endpoints are configured:

```dart
// In lib/service/endpoints.dart - already configured
static String baseURL = "https://api.banatalk.com/api/v1/";
static String usersURL = "auth/users";

// Endpoints automatically constructed:
// POST /api/v1/auth/users/:userId/vip/activate
// POST /api/v1/auth/users/:userId/vip/deactivate
// GET  /api/v1/auth/users/:userId/vip/status
// POST /api/v1/auth/users/:userId/upgrade-visitor
// GET  /api/v1/auth/users/:userId/visitor/limits
// PUT  /api/v1/auth/users/:userId/mode
```

## Testing Checklist

### Visitor Mode Testing
- [ ] Visitor can send up to 5 messages
- [ ] Visitor can view up to 10 profiles
- [ ] Dialog appears when limit is reached
- [ ] Visitor can see their remaining limits
- [ ] Visitor can upgrade to regular account

### Regular User Testing
- [ ] Regular user has no daily limits
- [ ] Regular user can upgrade to VIP
- [ ] All standard features work

### VIP Testing
- [ ] VIP subscription can be activated
- [ ] VIP badge displays correctly
- [ ] All VIP features are unlocked
- [ ] VIP status screen shows subscription details
- [ ] VIP subscription can be cancelled

### UI Testing
- [ ] VIP plans screen displays correctly
- [ ] Payment screen works
- [ ] Usage indicators show correct data
- [ ] Feature gates work properly
- [ ] All badges display correctly

## Payment Integration

The current implementation uses a simulated payment flow. To integrate real payments:

1. Add payment provider SDK (Stripe, PayPal, etc.)
2. Update `lib/pages/vip/vip_payment_screen.dart`
3. Replace the simulated payment with actual payment processing
4. Handle payment webhooks from your backend

Example with Stripe:

```dart
// Add to pubspec.yaml
// flutter_stripe: ^latest_version

// In vip_payment_screen.dart
import 'package:flutter_stripe/flutter_stripe.dart';

Future<void> _processPayment() async {
  // Initialize payment intent from your backend
  final paymentIntent = await createPaymentIntent();

  // Present payment sheet
  await Stripe.instance.presentPaymentSheet(
    parameters: SetupPaymentSheetParameters(
      paymentIntentClientSecret: paymentIntent['client_secret'],
      merchantDisplayName: 'BananaTalk',
    ),
  );

  // Call VIP activation API
  await VipService.activateVip(
    userId: widget.userId,
    plan: widget.plan,
    paymentMethod: 'stripe',
  );
}
```

## Dependencies

Make sure these packages are in your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  intl: ^0.18.1  # For date formatting in VIP status screen
  flutter_riverpod: ^2.4.9  # Already in your project
```

## Next Steps

1. **Update your User Provider/State Management** to include the new fields when fetching user data from the backend
2. **Add Feature Gates** to protected features (messages, profile views, etc.)
3. **Test the complete flow** from visitor → regular → VIP
4. **Integrate real payment processing** when ready
5. **Add analytics** to track conversions and upgrade flows

## Example Usage in Chat

```dart
// In your chat screen
class ChatScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(userProvider); // Your user provider

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat'),
        actions: [
          // Show usage indicator for visitors
          if (currentUser.isVisitor && currentUser.visitorLimitations != null)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: VisitorUsageIndicator(
                limitations: currentUser.visitorLimitations!,
                compact: true,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(child: MessagesList()),

          // Input field
          MessageInput(
            onSend: (message) async {
              // Check feature gate before sending
              if (!FeatureGate.canSendMessage(currentUser)) {
                await FeatureGate.showLimitReachedDialog(
                  context: context,
                  user: currentUser,
                  limitType: 'message',
                );
                return;
              }

              // Send message
              await sendMessage(message);
            },
          ),
        ],
      ),
    );
  }
}
```

## Support

For questions or issues with the VIP integration, please refer to:
- Backend API documentation
- Payment provider documentation
- Flutter documentation for state management
