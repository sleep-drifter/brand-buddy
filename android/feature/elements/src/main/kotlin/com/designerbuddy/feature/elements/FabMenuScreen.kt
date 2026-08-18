package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.FloatingActionButtonMenu
import androidx.compose.material3.FloatingActionButtonMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleFloatingActionButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/** M3 Expressive FAB menu: a toggle FAB that morphs open into a stack of
 * labeled actions. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun FabMenuScreen() {
    var expanded by remember { mutableStateOf(false) }

    Box(modifier = Modifier.fillMaxSize()) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        ) {
            demoSection(
                title = "FAB menu",
                description = "Tap the FAB in the corner — it morphs into a menu of labeled actions instead of launching a bare speed-dial.",
            ) {
                Text("The menu closes when an action is chosen.")
            }
        }

        FloatingActionButtonMenu(
            expanded = expanded,
            button = {
                ToggleFloatingActionButton(
                    checked = expanded,
                    onCheckedChange = { expanded = it },
                ) {
                    Icon(
                        if (expanded) Icons.Filled.Close else Icons.Filled.Add,
                        contentDescription = if (expanded) "Close menu" else "Open menu",
                    )
                }
            },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp),
        ) {
            FloatingActionButtonMenuItem(
                onClick = { expanded = false },
                text = { Text("Compose") },
                icon = { Icon(Icons.Filled.Edit, contentDescription = null) },
            )
            FloatingActionButtonMenuItem(
                onClick = { expanded = false },
                text = { Text("Add photo") },
                icon = { Icon(Icons.Filled.Image, contentDescription = null) },
            )
            FloatingActionButtonMenuItem(
                onClick = { expanded = false },
                text = { Text("Record") },
                icon = { Icon(Icons.Filled.Mic, contentDescription = null) },
            )
        }
    }
}
