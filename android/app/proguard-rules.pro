# ---- Flutter ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Flutter deferred components reference Play Core, which we don't bundle.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ---- Firebase / Google ----
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
# Keep model classes that Firebase (de)serializes reflectively.
-keepclassmembers class * {
  @com.google.firebase.database.PropertyName *;
}

# ---- ML Kit (mobile_scanner barcode) ----
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ---- NFC ----
-keep class io.flutter.plugins.** { *; }

# ---- General reflection safety ----
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
-keepclasseswithmembernames class * {
  native <methods>;
}
-keepclassmembers enum * {
  public static **[] values();
  public static ** valueOf(java.lang.String);
}
# Suppress noisy warnings from optional deps
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
