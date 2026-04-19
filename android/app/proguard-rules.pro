# ─── CampusEats — Proguard Rules ─────────────────────────────────────────────
# Keep Flutter entry-points
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }

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
