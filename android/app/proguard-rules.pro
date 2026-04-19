# ─── CampusEats — Proguard Rules ─────────────────────────────────────────────
# Keep Flutter entry-points
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

# ── Play Core / Deferred Components ───────────────────────────────────────────
# Flutter's engine references Play Core SplitInstall classes for dynamic feature
# delivery. We do NOT use deferred components, so these classes are absent from
# our build. Tell R8 to suppress the missing-class errors rather than fail.
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# Keep Firebase / Google services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Razorpay
-keep class com.razorpay.** { *; }
-keepattributes *Annotation*

# Keep notification channel classes for flutter_local_notifications
-keep class com.dexterous.** { *; }

# unified_esc_pos_printer — keep USB/BT JNI bridge
-keep class com.github.elrizwiraswara.** { *; }

# General: keep all Serializable classes for Gson / JSON deserialization
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
