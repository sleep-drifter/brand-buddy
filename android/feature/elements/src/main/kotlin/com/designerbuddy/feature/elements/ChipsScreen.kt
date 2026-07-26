package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.AssistChip
import androidx.compose.material3.AssistChipDefaults
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.InputChip
import androidx.compose.material3.InputChipDefaults
import androidx.compose.material3.SuggestionChip
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
fun ChipsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Assist & suggestion",
            description = "Contextual actions and smart suggestions.",
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                AssistChip(
                    onClick = {},
                    label = { Text("Set reminder") },
                    leadingIcon = {
                        Icon(
                            Icons.Filled.Notifications,
                            contentDescription = null,
                            modifier = Modifier.size(AssistChipDefaults.IconSize),
                        )
                    },
                )
                SuggestionChip(onClick = {}, label = { Text("Reply: On my way") })
            }
        }

        demoSection(title = "Filter", description = "Toggleable, with a selected check.") {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                var selectedA by remember { mutableStateOf(true) }
                FilterChip(
                    selected = selectedA,
                    onClick = { selectedA = !selectedA },
                    label = { Text("Favorites") },
                    leadingIcon = if (selectedA) {
                        {
                            Icon(
                                Icons.Filled.Check,
                                contentDescription = null,
                                modifier = Modifier.size(FilterChipDefaults.IconSize),
                            )
                        }
                    } else {
                        null
                    },
                )
                var selectedB by remember { mutableStateOf(false) }
                FilterChip(
                    selected = selectedB,
                    onClick = { selectedB = !selectedB },
                    label = { Text("Recent") },
                )
            }
        }

        demoSection(title = "Input", description = "User-entered values, removable.") {
            var visible by remember { mutableStateOf(true) }
            if (visible) {
                InputChip(
                    selected = false,
                    onClick = { visible = false },
                    label = { Text("designer@buddy.app") },
                    avatar = {
                        Icon(
                            Icons.Filled.Email,
                            contentDescription = null,
                            modifier = Modifier.size(InputChipDefaults.AvatarSize),
                        )
                    },
                    trailingIcon = {
                        Icon(
                            Icons.Filled.Close,
                            contentDescription = "Remove",
                            modifier = Modifier.size(InputChipDefaults.IconSize),
                        )
                    },
                )
            } else {
                SuggestionChip(onClick = { visible = true }, label = { Text("Restore chip") })
            }
        }

        demoSection(title = "Badges", description = "Counts and dots on anchors.") {
            Row(horizontalArrangement = Arrangement.spacedBy(32.dp)) {
                BadgedBox(badge = { Badge { Text("12") } }) {
                    Icon(Icons.Filled.Email, contentDescription = "Inbox")
                }
                BadgedBox(badge = { Badge() }) {
                    Icon(Icons.Filled.Settings, contentDescription = "Settings")
                }
            }
        }
    }
}
