plugins {
    id("designerbuddy.android.library.compose")
}

android {
    namespace = "com.designerbuddy.core.catalog"
}

dependencies {
    api(platform(libs.androidx.compose.bom))
    api(libs.androidx.compose.ui)

    testImplementation(libs.junit4)
}
