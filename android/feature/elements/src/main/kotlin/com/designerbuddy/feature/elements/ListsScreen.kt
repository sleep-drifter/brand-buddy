package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Checkbox
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

@Composable
fun ListsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "List items",
            description = "One-, two-, and three-line rows with leading/trailing slots.",
        ) {
            ListItem(
                headlineContent = { Text("Single line") },
                leadingContent = { Icon(Icons.Filled.Person, contentDescription = null) },
            )
            HorizontalDivider()
            ListItem(
                headlineContent = { Text("Two lines") },
                supportingContent = { Text("Supporting text") },
                leadingContent = { Icon(Icons.Filled.Folder, contentDescription = null) },
                trailingContent = {
                    var on by remember { mutableStateOf(true) }
                    Switch(checked = on, onCheckedChange = { on = it })
                },
            )
            HorizontalDivider()
            var checked by remember { mutableStateOf(false) }
            ListItem(
                headlineContent = { Text("Three lines") },
                supportingContent = {
                    Text("Longer supporting text that wraps to a second line for emphasis")
                },
                overlineContent = { Text("OVERLINE") },
                trailingContent = {
                    Checkbox(checked = checked, onCheckedChange = { checked = it })
                },
            )
        }

        demoSection(
            title = "Swipeable row",
            description = "Swipe the row toward either edge to dismiss.",
        ) {
            var dismissed by remember { mutableStateOf(false) }
            if (!dismissed) {
                val state = rememberSwipeToDismissBoxState(
                    confirmValueChange = { value ->
                        if (value != SwipeToDismissBoxValue.Settled) dismissed = true
                        true
                    },
                )
                SwipeToDismissBox(
                    state = state,
                    backgroundContent = {
                        Surface(
                            color = MaterialTheme.colorScheme.errorContainer,
                            modifier = Modifier.fillMaxSize(),
                        ) {
                            androidx.compose.foundation.layout.Box(
                                contentAlignment = Alignment.CenterStart,
                                modifier = Modifier
                                    .fillMaxSize()
                                    .padding(horizontal = 20.dp),
                            ) {
                                Icon(
                                    Icons.Filled.Delete,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.onErrorContainer,
                                )
                            }
                        }
                    },
                ) {
                    Surface(color = MaterialTheme.colorScheme.surfaceContainerHigh) {
                        ListItem(
                            modifier = Modifier.fillMaxWidth(),
                            headlineContent = { Text("Swipe me away") },
                            supportingContent = { Text("Reveals a delete affordance") },
                        )
                    }
                }
            } else {
                Text(
                    "Row dismissed.",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
        }
    }
}
