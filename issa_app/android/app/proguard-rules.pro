# ProGuard / R8 Rules for ISSA Sales Tracker

# Flutter engine and plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google ML Kit (Prevent obfuscation of dependency injection & components)
-keep class com.google.mlkit.** { *; }
-keep interface com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# SQLite3 / Drift
-keep class org.sqlite.** { *; }
-keep class com.simonbinder.sqlite3_flutter_libs.** { *; }
-dontwarn org.sqlite.**

# Gson / JSON / protobuf
-keepattributes Signature
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
  <fields>;
}
