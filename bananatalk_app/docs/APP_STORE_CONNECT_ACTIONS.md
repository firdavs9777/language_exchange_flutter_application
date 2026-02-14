# Actions Required in App Store Connect

## To Remove/Disable In-App Purchases

Since the VIP subscription feature is not currently active in your app, you have two options:

### Option 1: Remove In-App Purchase Products (Recommended)

1. **Go to App Store Connect**
   - Navigate to your app
   - Click on **"Features"** in the left sidebar
   - Click on **"In-App Purchases"**

2. **Delete or Remove Products**
   - Find each of the three products:
     - `com.bananatalk.bananatalkApp.monthly`
     - `com.bananatalk.bananatalkApp.quarterly`
     - `com.bananatalk.bananatalkApp.yearly`
   
   - For each product:
     - Click on the product
     - Scroll to the bottom
     - Click **"Remove from Sale"** or **"Delete"** (if available)
     - This will remove them from the current app version

3. **Note:** You cannot completely delete in-app purchases once created, but you can remove them from sale, which effectively disables them.

### Option 2: Keep Products but Mark as Not Available

If you want to keep the products for future use:

1. **Go to each In-App Purchase product**
2. **Change status to "Ready to Submit" but don't submit**
3. **Or mark as "Removed from Sale"**
4. This keeps them in your account but they won't be active

## Important Notes

⚠️ **You cannot completely delete in-app purchases** - once created, they remain in App Store Connect. However, removing them from sale effectively disables them.

✅ **Best Practice:** Remove them from sale and mention in your response to Apple that they are not active in the current version.

## What to Do Right Now

1. **Reply to Apple** using the message in `APPLE_RESPONSE.md`
2. **Go to App Store Connect** → Your App → Features → In-App Purchases
3. **Remove from Sale** all three VIP subscription products
4. **Resubmit** your app for review (if needed)

## If You Want to Re-enable Later

When you're ready to activate VIP subscriptions:
1. Re-enable the products in App Store Connect
2. Uncomment the VIP navigation code in the app
3. Submit an update with the feature enabled

