# ProGuard / R8 Rules for ISSA Sales Tracker

# Prevent obfuscation and optimization from breaking ML Kit dynamic dependency injection
-dontoptimize
-dontobfuscate

# Flutter engine and plugins
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# Google ML Kit (Prevent stripping/obfuscation of dependency injection & components)
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
