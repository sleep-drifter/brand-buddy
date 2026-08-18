import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.JavaVersion
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.kotlin.dsl.configure

/**
 * Base configuration for library modules WITHOUT Compose (e.g. :core:data).
 * Compose modules use designerbuddy.android.library.compose instead — the
 * Compose compiler refuses to run on modules with no Compose runtime on the
 * classpath, so Compose must not be forced onto every library.
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

                testOptions {
                    unitTests {
                        // Robolectric-based tests (screenshots) need resources.
                        isIncludeAndroidResources = true
                    }
                }
            }
        }
    }
}
