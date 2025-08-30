# Flutter and Dart optimizations
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter embedding
-keep class io.flutter.embedding.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Crashlytics
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Play Store / Play Core (to fix the missing classes error)
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**

# Keep all model classes (if you have any serialized objects)
-keep class com.aacpp.app.models.** { *; }

# TTS and Audio
-keep class android.speech.tts.** { *; }
-keep class android.media.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Image picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Shared preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Path provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Vibration
-keep class nl.skyware.flutter_vibrate.** { *; }

# Hive database
-keep class hive_flutter.** { *; }
# Keep Hive generated classes (commented out - not standard ProGuard syntax)
# -keep class **/*.g.dart

# Encrypted storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Audio players
-keep class xyz.luan.audioplayers.** { *; }

# Remove debug logs in release
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
}
