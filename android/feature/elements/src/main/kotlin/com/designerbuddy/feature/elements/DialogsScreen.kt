package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

@Composable
fun DialogsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Basic dialog",
            description = "Title, supporting text, confirm and dismiss actions.",
        ) {
            var open by remember { mutableStateOf(false) }
            OutlinedButton(onClick = { open = true }) { Text("Show dialog") }
            if (open) {
                AlertDialog(
                    onDismissRequest = { open = false },
                    title = { Text("Discard draft?") },
                    text = { Text("Your changes haven't been saved. This can't be undone.") },
                    confirmButton = {
                        TextButton(onClick = { open = false }) { Text("Discard") }
                    },
                    dismissButton = {
                        TextButton(onClick = { open = false }) { Text("Cancel") }
                    },
                )
            }
        }

        demoSection(title = "With hero icon", description = "Icon centers above the title.") {
            var open by remember { mutableStateOf(false) }
            OutlinedButton(onClick = { open = true }) { Text("Show icon dialog") }
            if (open) {
                AlertDialog(
                    onDismissRequest = { open = false },
                    icon = { Icon(Icons.Filled.Delete, contentDescription = null) },
                    title = { Text("Empty trash?") },
                    text = { Text("All items in the trash will be permanently deleted.") },
                    confirmButton = {
                        TextButton(onClick = { open = false }) { Text("Empty trash") }
                    },
                    dismissButton = {
                        TextButton(onClick = { open = false }) { Text("Cancel") }
                    },
                )
            }
        }
    }
}
