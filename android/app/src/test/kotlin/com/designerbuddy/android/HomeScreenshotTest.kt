package com.designerbuddy.android

import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onRoot
import com.designerbuddy.core.designsystem.DesignerBuddyTheme
import com.designerbuddy.feature.home.HomeScreen
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@Config(sdk = [35], qualifiers = "w411dp-h891dp-normal-long-notround-any-420dpi-keyshidden-nonav")
class HomeScreenshotTest {

    @get:Rule
    val composeRule = createComposeRule()

    @Test
    fun home() {
        composeRule.setContent {
            DesignerBuddyTheme(dynamicColor = false) {
                HomeScreen(
                    registry = catalogRegistry,
                    pinnedIds = setOf("elements/buttons"),
                    onTogglePin = {},
                    onOpen = {},
                )
            }
        }
        composeRule.onRoot().captureRoboImage("screenshots/home.png")
    }
}
