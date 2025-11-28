# Keep just_audio classes
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# Keep audio_service classes
-keep class com.ryanheise.audioservice.** { *; }

# Keep MediaSession classes
-keep class android.support.v4.media.** { *; }
-keep class androidx.media.** { *; }

# Keep audio codecs
-keep class com.google.android.exoplayer2.ext.** { *; }
-keep class com.google.android.exoplayer2.extractor.** { *; }
-keep class com.google.android.exoplayer2.audio.** { *; }

# Prevent obfuscation of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
