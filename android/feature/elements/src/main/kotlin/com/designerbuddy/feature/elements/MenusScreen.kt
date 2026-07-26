package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

@Composable
fun MenusScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Icon-anchored menu",
            description = "The overflow (⋮) pattern.",
        ) {
            Box {
                var open by remember { mutableStateOf(false) }
                IconButton(onClick = { open = true }) {
                    Icon(Icons.Filled.MoreVert, contentDescription = "More options")
                }
                DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
                    DropdownMenuItem(
                        text = { Text("Edit") },
                        onClick = { open = false },
                        leadingIcon = { Icon(Icons.Filled.Edit, contentDescription = null) },
                    )
                    DropdownMenuItem(
                        text = { Text("Share") },
                        onClick = { open = false },
                        leadingIcon = { Icon(Icons.Filled.Share, contentDescription = null) },
                    )
                    HorizontalDivider()
                    DropdownMenuItem(
                        text = { Text("Delete") },
                        onClick = { open = false },
                        leadingIcon = { Icon(Icons.Filled.Delete, contentDescription = null) },
                    )
                }
            }
        }

        demoSection(
            title = "Button-anchored menu",
            description = "Menus can anchor to any element.",
        ) {
            Box {
                var open by remember { mutableStateOf(false) }
                var choice by remember { mutableStateOf("Newest first") }
                OutlinedButton(onClick = { open = true }) { Text("Sort: $choice") }
                DropdownMenu(expanded = open, onDismissRequest = { open = false }) {
                    listOf("Newest first", "Oldest first", "A–Z").forEach { option ->
                        DropdownMenuItem(
                            text = { Text(option) },
                            onClick = {
                                choice = option
                                open = false
                            },
                        )
                    }
                }
            }
        }
    }
}
