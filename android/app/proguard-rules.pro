# R8 rules for release builds (isMinifyEnabled = true).
# Most plugins ship their own rules; these cover the ones that use
# reflection/JNI and are known to break when shrunk.

# Flutter references Play Core for deferred components, which this app
# doesn't use. Without this, R8 fails with "Missing class
# com.google.android.play.core...".
-dontwarn com.google.android.play.core.**

# Agora voice calls (native code calls back into these classes via JNI).
-keep class io.agora.** { *; }
-dontwarn io.agora.**

# flutter_local_notifications (uses Gson to store scheduled notifications).
-keep class com.dexterous.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*

# just_audio / just_audio_background (ExoPlayer media session).
-keep class com.ryanheise.** { *; }

# Sign in with Apple / Google sign-in callbacks.
-keep class com.aboutyou.dart_packages.sign_in_with_apple.** { *; }

# Keep stack traces readable in Firebase Crashlytics / Play Console.
-keepattributes SourceFile,LineNumberTable
