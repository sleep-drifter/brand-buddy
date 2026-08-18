object AndroidConfig {
    // 37 because the Material 3 Expressive alphas compile against the next
    // Android API level (their AAR metadata rejects compileSdk 36).
    // compileSdk governs which APIs are visible at compile time only;
    // runtime behavior stays opted in at targetSdk 36.
    const val COMPILE_SDK = 37
    // AGSL RuntimeShader, the native Photo Picker, POST_NOTIFICATIONS, and
    // predictive back all require 33; see ANDROID_PLAN.md §3.
    const val MIN_SDK = 33
    const val TARGET_SDK = 36
}
