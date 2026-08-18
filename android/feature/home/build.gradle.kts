plugins {
    id("designerbuddy.android.library.compose")
}

android {
    namespace = "com.designerbuddy.feature.home"
}

dependencies {
    api(project(":core:catalog"))
    implementation(project(":core:designsystem"))

    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.material.icons.extended)
    implementation(libs.androidx.compose.ui.tooling.preview)

    debugImplementation(libs.androidx.compose.ui.tooling)
}
