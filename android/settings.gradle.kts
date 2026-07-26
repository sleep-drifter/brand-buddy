pluginManagement {
    includeBuild("build-logic")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode = RepositoriesMode.FAIL_ON_PROJECT_REPOS
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "designer-buddy"

include(":app")
include(":core:catalog")
include(":core:data")
include(":core:designsystem")
include(":feature:elements")
include(":feature:home")
