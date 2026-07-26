plugins {
    `kotlin-dsl`
}

group = "com.designerbuddy.buildlogic"

dependencies {
    compileOnly(libs.android.gradlePlugin)
}

gradlePlugin {
    plugins {
        register("androidApplication") {
            id = "designerbuddy.android.application"
            implementationClass = "AndroidApplicationConventionPlugin"
        }
        register("androidLibrary") {
            id = "designerbuddy.android.library"
            implementationClass = "AndroidLibraryConventionPlugin"
        }
    }
}
