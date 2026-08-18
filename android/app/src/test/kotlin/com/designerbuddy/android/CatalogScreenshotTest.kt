package com.designerbuddy.android

import androidx.compose.material3.Surface
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import com.designerbuddy.core.designsystem.DesignerBuddyTheme
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.ParameterizedRobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

/**
 * Renders every catalog page and records a screenshot. Parameterized over the
 * registry, so new pages are covered automatically. CI runs
 * `recordRoborazziDebug` and uploads the images as a workflow artifact —
 * the visual record of the whole catalog per commit.
 */
@RunWith(ParameterizedRobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w411dp-h891dp-normal-long-notround-any-420dpi-keyshidden-nonav")
class CatalogScreenshotTest(private val entryId: String) {

    @get:Rule
    val composeRule = createComposeRule()

    companion object {
        @JvmStatic
        @ParameterizedRobolectricTestRunner.Parameters(name = "{0}")
        fun entryIds(): List<String> = catalogRegistry.all.map { it.id }
    }

    @Test
    fun screenshot() {
        val entry = requireNotNull(catalogRegistry.entry(entryId))
        composeRule.setContent {
            // Fixed (non-dynamic) color scheme so renders are deterministic.
            DesignerBuddyTheme(dynamicColor = false) {
                Surface { entry.content() }
            }
        }
        composeRule.onRoot()
            .captureRoboImage("screenshots/${entryId.replace('/', '_')}.png")
    }
}
