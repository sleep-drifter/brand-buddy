package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material3.ButtonGroup
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/**
 * M3 Expressive button group: press-and-hold any item — it widens while its
 * neighbors compress, a built-in interaction of the container (no custom
 * animation code).
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ButtonGroupsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Clickable group",
            description = "Press an item and hold — watch the widths redistribute.",
        ) {
            ButtonGroup(
                overflowIndicator = { _ ->
                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.MoreVert, contentDescription = "More")
                    }
                },
            ) {
                clickableItem(onClick = {}, label = "Day")
                clickableItem(onClick = {}, label = "Week")
                clickableItem(onClick = {}, label = "Month")
            }
        }

        demoSection(
            title = "Toggleable group",
            description = "Single-select with the same squeeze interaction.",
        ) {
            var selected by remember { mutableIntStateOf(0) }
            ButtonGroup(
                overflowIndicator = { _ ->
                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.MoreVert, contentDescription = "More")
                    }
                },
            ) {
                listOf("List", "Grid", "Map").forEachIndexed { index, label ->
                    toggleableItem(
                        checked = selected == index,
                        onCheckedChange = { if (it) selected = index },
                        label = label,
                    )
                }
            }
        }
    }
}
