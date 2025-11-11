# --- Google ML Kit Text Recognition Keep Rules ---
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Prévention de suppression des classes dynamiques utilisées par le plugin
-keep class com.google_mlkit_text_recognition.** { *; }
