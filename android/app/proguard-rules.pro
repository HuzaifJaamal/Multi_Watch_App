# Keep Jieli SDK
-keep class com.jieli.** { *; }
-dontwarn com.jieli.**

# Ignore missing JP2 classes (JPEG2000)
-dontwarn com.gemalto.jp2.**

# Keep Inuker BLE
-keep class com.inuker.bluetooth.** { *; }
-dontwarn com.inuker.bluetooth.**

# Keep PDFBox classes
-keep class com.tom_roush.pdfbox.** { *; }
-dontwarn com.tom_roush.pdfbox.**

# Keep Veepoo Protocol
-keep class com.veepoo.protocol.** { *; }
-dontwarn com.veepoo.protocol.**

# Keep native bindings
-keepclasseswithmembernames class * {
    native <methods>;

}
