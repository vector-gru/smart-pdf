# ── Flutter / general ────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ── Google ML Kit — text recognition ────────────────────────────────────────
# The plugin references all script options at runtime even when only Latin is
# used, so keep them all to prevent R8 "missing class" errors.
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }

# ── Google ML Kit — commons ──────────────────────────────────────────────────
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# ── Suppress warnings for the same missing classes ───────────────────────────
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ── Flutter deferred components (Play Core) ──────────────────────────────────
# Flutter references Play Core deferred component APIs which are not present
# in standard app builds. Suppress the warnings so R8 doesn't fail.
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.splitcompat.**
