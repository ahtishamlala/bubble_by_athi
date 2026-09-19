# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Mobile Ads SDK (AdMob)
-keep public class com.google.android.gms.ads.** {
   public *;
}
-keep public class com.google.ads.** {
   public *;
}
-keep class com.google.android.gms.ads.internal.** { *; }
-keep class com.google.android.gms.ads.MobileAdsInitProvider { *; }
-keep class com.google.android.gms.ads.AdActivity { *; }

# Flutter Google Mobile Ads Plugin
-keep class io.flutter.plugins.googlemobileads.** { *; }

# Shared Preferences Plugin
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# AndroidX Startup & Lifecycle
-keep class androidx.startup.** { *; }
-keep class androidx.lifecycle.** { *; }

# For reflection / JNI
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes Exceptions
-dontwarn com.google.android.gms.ads.**
-dontwarn io.flutter.plugins.googlemobileads.**
