package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ElevatedToggleButton
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.OutlinedToggleButton
import androidx.compose.material3.Text
import androidx.compose.material3.ToggleButton
import androidx.compose.material3.TonalToggleButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/**
 * M3 Expressive toggle buttons: press them — the container physically morphs
 * shape (round ↔ squarish) between unchecked and checked. The morph is the
 * component's built-in spring, not custom animation code.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun ToggleButtonsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Shape-morphing toggles",
            description = "Watch the corners: checked state squares off, pressing squishes. All four emphasis variants.",
        ) {
            var a by rememberSaveable { mutableStateOf(true) }
            var b by rememberSaveable { mutableStateOf(false) }
            var c by rememberSaveable { mutableStateOf(false) }
            var d by rememberSaveable { mutableStateOf(true) }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ToggleButton(checked = a, onCheckedChange = { a = it }) { Text("Filled") }
                TonalToggleButton(checked = b, onCheckedChange = { b = it }) { Text("Tonal") }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                ElevatedToggleButton(checked = c, onCheckedChange = { c = it }) { Text("Elevated") }
                OutlinedToggleButton(checked = d, onCheckedChange = { d = it }) { Text("Outlined") }
            }
        }

        demoSection(
            title = "As a formatting bar",
            description = "Independent toggles side by side — the expressive take on the classic B/I/U row.",
        ) {
            var bold by remember { mutableStateOf(true) }
            var italic by remember { mutableStateOf(false) }
            var underline by remember { mutableStateOf(false) }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                TonalToggleButton(checked = bold, onCheckedChange = { bold = it }) { Text("B") }
                TonalToggleButton(checked = italic, onCheckedChange = { italic = it }) { Text("I") }
                TonalToggleButton(checked = underline, onCheckedChange = { underline = it }) { Text("U") }
            }
        }
    }
}
