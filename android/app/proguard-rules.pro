# google_mlkit_text_recognition's TextRecognizer references the optional
# Chinese/Devanagari/Japanese/Korean script recognizer classes
# unconditionally, even though only the Latin-script recognizer
# (TextRecognitionScript.latin) is ever requested in this app and only its
# dependency is pulled in. R8 can't resolve those classes at release-build
# minification time since their optional per-script mlkit dependencies
# aren't on the classpath; the code paths that reference them are never
# reached, so it's safe to tell R8 to ignore them rather than fail the
# build.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
