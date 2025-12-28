# Environment Variables Setup

This project uses environment variables to store sensitive configuration like Firebase API keys. This prevents secrets from being committed to version control.

## Setup Instructions

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Fill in your Firebase configuration:**
   - Open `.env` in a text editor
   - Replace all placeholder values with your actual Firebase credentials
   - You can find these values in your Firebase Console:
     - Go to Project Settings
     - Scroll down to "Your apps"
     - Select your app (Web, Android, iOS, etc.)
     - Copy the configuration values

3. **For Firebase config files:**
   - `android/app/google-services.json` - Download from Firebase Console for Android
   - `ios/Runner/GoogleService-Info.plist` - Download from Firebase Console for iOS
   - These files are required for the native Firebase SDKs to work
   - Example files (`.example`) are provided as templates

## Important Notes

- **Never commit `.env` to version control** - It's already in `.gitignore`
- The `.env.example` file is safe to commit as it contains no real secrets
- If you're setting up a new environment, copy `.env.example` to `.env` and fill in your values
- The app will fail to start if `.env` is missing or incomplete

## Firebase Configuration Files

The following files contain API keys but are required for the app to build:
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

**Note:** These files are currently committed to the repository because:
1. They're required for the app to build
2. The API keys in them are client-side Firebase keys (safe to be public)
3. Firebase security rules protect your backend, not these client-side keys

If GitHub secret scanning flags these files, you have two options:

**Option 1: Keep them committed (Recommended)**
- These are client-side keys meant to be public
- Firebase security is handled by security rules, not by hiding these keys
- This is the standard practice for Firebase projects

**Option 2: Remove them from version control**
- Add them to `.gitignore`
- Use the `.example` files as templates
- Require developers to download them from Firebase Console
- Note: This will make setup more complex for new developers

## Troubleshooting

If you see errors about missing environment variables:
1. Ensure `.env` file exists in the project root
2. Check that all required variables are set (compare with `.env.example`)
3. Restart the app after creating/updating `.env`
4. Run `flutter pub get` to ensure dependencies are installed

