package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.FormatPaint
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.HorizontalFloatingToolbar
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/** M3 Expressive floating toolbar: a pill of actions that expands and
 * collapses, replacing many bottom-app-bar uses. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun FloatingToolbarScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Horizontal floating toolbar",
            description = "Floats above content instead of docking to an edge. Toggle expansion below.",
        ) {
            var expanded by remember { mutableStateOf(true) }
            Column(
                modifier = Modifier.fillMaxWidth(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                HorizontalFloatingToolbar(expanded = expanded) {
                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.Edit, contentDescription = "Edit")
                    }
                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.FormatPaint, contentDescription = "Style")
                    }
                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.Share, contentDescription = "Share")
                    }
                    IconButton(onClick = {}) {
                        Icon(Icons.Filled.Delete, contentDescription = "Delete")
                    }
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("Expanded")
                    Switch(checked = expanded, onCheckedChange = { expanded = it })
                }
            }
        }
    }
}
