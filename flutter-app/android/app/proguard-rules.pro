# Flutter & MediaPipe Proguard Rules
-dontobfuscate
-dontoptimize
-keep class com.google.mediapipe.** { *; }
-dontwarn com.google.mediapipe.**
-keep class com.google.common.flogger.** { *; }
-dontwarn com.google.common.flogger.**
-keep class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,SourceFile,LineNumberTable
-keepclasseswithmembernames class * {
    native <methods>;
}

