package com.designerbuddy.android

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import com.designerbuddy.core.data.PinsRepository
import com.designerbuddy.core.designsystem.DesignerBuddyTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        installSplashScreen()
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)

        val pinsRepository = PinsRepository(applicationContext)

        setContent {
            DesignerBuddyTheme {
                DesignerBuddyApp(pinsRepository = pinsRepository)
            }
        }
    }
}
