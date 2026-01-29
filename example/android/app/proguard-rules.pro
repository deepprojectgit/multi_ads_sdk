# Facebook Audience Network
-keep class com.facebook.ads.** { *; }
-keep class com.facebook.infer.annotation.** { *; }
-dontwarn com.facebook.ads.**

# Google Play Services Ads
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom exceptions
-keep public class * extends java.lang.Exception

# Keep annotation default values
-keepattributes AnnotationDefault

# Keep line numbers for debugging
-keepattributes SourceFile,LineNumberTable

# Keep generic signatures
-keepattributes Signature

# Keep exceptions
-keepattributes Exceptions
