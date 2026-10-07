# R8 keeps for this app. Flutter's Gradle plugin already prepends
# proguard-android-optimize.txt and flutter_proguard_rules.pro (which keeps
# every FlutterPlugin implementation), and most plugins ship their own
# consumer rules inside their AAR — flutter_webrtc (LiveKit), mobile_scanner,
# flutter_callkit_incoming, Firebase, Play Billing, Play Services Ads.
# Only what those do not cover belongs here.

# flutter_local_notifications serialises scheduled notifications with Gson,
# which reads generic signatures and field names reflectively at runtime.
-keep class com.dexterous.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Play Core split-install APIs are referenced by the Flutter embedding's
# deferred-components path. This app ships no deferred components, so the
# classes are absent at compile time and R8 would fail on the dangling refs.
-dontwarn com.google.android.play.core.**
