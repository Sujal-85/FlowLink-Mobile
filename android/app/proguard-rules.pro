# Keep Razorpay SDK classes
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**

# Ignore missing ProGuard annotation classes used by some SDKs
-dontwarn proguard.annotation.**
-keep class proguard.annotation.Keep
-keep class proguard.annotation.KeepName
-keep class proguard.annotation.KeepClassMembers

# Respect @Keep annotations
-keep class androidx.annotation.Keep
-keepclasseswithmembers class * {
    @androidx.annotation.Keep *;
    @proguard.annotation.Keep *;
    @proguard.annotation.KeepName *;
    @proguard.annotation.KeepClassMembers *;
}
