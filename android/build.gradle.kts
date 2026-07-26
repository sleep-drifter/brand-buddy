// These plugins must be on the root build classpath so the convention
// plugins in build-logic can apply them by id.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.compose) apply false
}
