import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.JavaVersion
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure

/**
 * Base configuration for the app module. Kotlin compilation comes from AGP 9's
 * built-in Kotlin support; the Compose compiler plugin is still required
 * (AGP fails configuration without it when compose is enabled).
 */
class AndroidApplicationConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) {
        with(target) {
            pluginManager.apply("com.android.application")
            pluginManager.apply("org.jetbrains.kotlin.plugin.compose")

            extensions.configure<ApplicationExtension> {
                compileSdk = AndroidConfig.COMPILE_SDK

                defaultConfig {
                    minSdk = AndroidConfig.MIN_SDK
                    targetSdk = AndroidConfig.TARGET_SDK
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
