// AGP must be on the root build classpath so the convention plugins in
// build-logic (which declare it compileOnly) can apply it.
plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
}
