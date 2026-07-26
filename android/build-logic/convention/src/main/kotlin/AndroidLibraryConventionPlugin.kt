import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.JavaVersion
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure

/**
 * Base configuration for library modules. Every module in this project is a
 * Compose module, so Compose is enabled here; Kotlin and the Compose compiler
 * come from AGP 9's built-in Kotlin support.
 */
class AndroidLibraryConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            pluginManager.apply("com.android.library")

            extensions.configure<LibraryExtension> {
                compileSdk = AndroidConfig.COMPILE_SDK

                defaultConfig {
                    minSdk = AndroidConfig.MIN_SDK
                }

                compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_17
                    targetCompatibility = JavaVersion.VERSION_17
                }

                buildFeatures {
                    compose = true
                }
            }
        }
    }
}
