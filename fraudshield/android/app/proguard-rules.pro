# Flutter standard rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase standard rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Prevent R8 from stripping away JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep the models if you use reflection-based serialization (like dart:mirrors, though rare in Flutter)
# This is mostly for third-party SDKs that might use Java reflection.
-keep class com.citadel.fraudshield.v2.models.** { *; }
