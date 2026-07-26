package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SnackbarDuration
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection
import kotlinx.coroutines.launch

@Composable
fun SnackbarsScreen() {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        ) {
            demoSection(
                title = "Message only",
                description = "Brief, self-dismissing feedback.",
            ) {
                OutlinedButton(onClick = {
                    scope.launch { snackbarHostState.showSnackbar("Saved to library") }
                }) {
                    Text("Show snackbar")
                }
            }

            demoSection(title = "With action") {
                OutlinedButton(onClick = {
                    scope.launch {
                        snackbarHostState.showSnackbar(
                            message = "Item archived",
                            actionLabel = "Undo",
                            duration = SnackbarDuration.Short,
                        )
                    }
                }) {
                    Text("Show with action")
                }
            }

            demoSection(
                title = "With dismiss",
                description = "Indefinite duration until dismissed.",
            ) {
                OutlinedButton(onClick = {
                    scope.launch {
                        snackbarHostState.showSnackbar(
                            message = "No connection",
                            actionLabel = "Retry",
                            withDismissAction = true,
                            duration = SnackbarDuration.Indefinite,
                        )
                    }
                }) {
                    Text("Show persistent")
                }
            }
        }

        SnackbarHost(
            hostState = snackbarHostState,
            modifier = Modifier.align(Alignment.BottomCenter),
        )
    }
}
