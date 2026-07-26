plugins {
    id("designerbuddy.android.library")
}

android {
    namespace = "com.designerbuddy.core.data"
}

dependencies {
    api(libs.androidx.datastore.preferences)
}
