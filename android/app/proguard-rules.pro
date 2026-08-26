# TensorFlow Lite GPU delegate - class opsional, tidak dipakai runtime
# kalau tidak eksplisit pakai GPU acceleration.
-dontwarn org.tensorflow.lite.gpu.**
-keep class org.tensorflow.lite.** { *; }

-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options