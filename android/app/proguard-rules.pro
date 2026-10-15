# R8 rules for Singbook release builds. Deliberately minimal: Flutter, AndroidX
# and the Google libraries ship their own consumer rules. UNTESTED against a real
# release build in this change; verify on a device before distributing, and use
# -PminifyRelease=false to disable shrinking if a plugin misbehaves.

# Flutter deferred-component / Play Core references are optional.
-dontwarn com.google.android.play.core.**

# Cronet (embedded, cronetHttpNoPlay=true) and the Dart JNI bindings look classes
# and methods up by name at runtime, so they must not be renamed or removed.
-keep class org.chromium.net.** { *; }
-keep class org.chromium.base.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn org.chromium.**

# google_sign_in (Credential Manager / Google ID) reflection and parcelables.
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn androidx.credentials.**

# Keep annotations and generic signatures that JNI/reflection bindings rely on.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
