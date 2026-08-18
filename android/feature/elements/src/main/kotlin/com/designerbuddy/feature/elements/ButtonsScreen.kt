package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.outlined.FavoriteBorder
import androidx.compose.material3.Button
import androidx.compose.material3.ElevatedButton
import androidx.compose.material3.ExtendedFloatingActionButton
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconToggleButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.SmallFloatingActionButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

@Composable
fun ButtonsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Common buttons",
            description = "Emphasis ladder: filled → tonal → elevated → outlined → text.",
        ) {
            Button(onClick = {}) { Text("Filled") }
            FilledTonalButton(onClick = {}) { Text("Filled tonal") }
            ElevatedButton(onClick = {}) { Text("Elevated") }
            OutlinedButton(onClick = {}) { Text("Outlined") }
            TextButton(onClick = {}) { Text("Text") }
        }

        demoSection(title = "With icon") {
            Button(onClick = {}) {
                Icon(Icons.Filled.Add, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Create")
            }
            OutlinedButton(onClick = {}) {
                Icon(Icons.Filled.Edit, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(Modifier.width(8.dp))
                Text("Edit")
            }
        }

        demoSection(title = "Disabled") {
            Button(onClick = {}, enabled = false) { Text("Filled") }
            OutlinedButton(onClick = {}, enabled = false) { Text("Outlined") }
        }

        demoSection(title = "Icon buttons") {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                IconButton(onClick = {}) {
                    Icon(Icons.Filled.Add, contentDescription = "Add")
                }
                var liked by remember { mutableStateOf(false) }
                IconToggleButton(checked = liked, onCheckedChange = { liked = it }) {
                    Icon(
                        if (liked) Icons.Filled.Favorite else Icons.Outlined.FavoriteBorder,
                        contentDescription = "Like",
                    )
                }
            }
        }

        demoSection(title = "Floating action buttons") {
            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                SmallFloatingActionButton(onClick = {}) {
                    Icon(Icons.Filled.Add, contentDescription = "Add")
                }
                FloatingActionButton(onClick = {}) {
                    Icon(Icons.Filled.Add, contentDescription = "Add")
                }
                ExtendedFloatingActionButton(
                    onClick = {},
                    icon = { Icon(Icons.Filled.Add, contentDescription = null) },
                    text = { Text("Compose") },
                )
            }
        }
    }
}
