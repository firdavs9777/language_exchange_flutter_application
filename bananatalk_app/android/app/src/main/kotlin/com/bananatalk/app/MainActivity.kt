package com.bananatalk.app

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity: local_auth's Android side
// shows BiometricPrompt, which needs a FragmentActivity. With FlutterActivity
// LocalAuthPlugin returns ERROR_NOT_FRAGMENT_ACTIVITY on every authenticate()
// call, so biometric login never worked on Android.
class MainActivity: FlutterFragmentActivity() {
}
