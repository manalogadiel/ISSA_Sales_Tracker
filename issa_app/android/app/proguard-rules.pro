# ProGuard / R8 Rules for ISSA Sales Tracker

# ML Kit Text Recognition optional language packs (Chinese, Devanagari, Japanese, Korean)
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.vision.common.**
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.common.** { *; }

# SQLite / Drift
-keepclassmembers class * extends com.google.protobuf.GeneratedMessageLite {
  <fields>;
}
