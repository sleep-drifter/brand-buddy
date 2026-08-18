package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SheetsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Modal bottom sheet",
            description = "Standard detents: swipe between partial and full height.",
        ) {
            var open by remember { mutableStateOf(false) }
            OutlinedButton(onClick = { open = true }) { Text("Show sheet") }
            if (open) {
                ModalBottomSheet(onDismissRequest = { open = false }) {
                    SheetBody()
                }
            }
        }

        demoSection(
            title = "Full-height start",
            description = "skipPartiallyExpanded opens straight to full height.",
        ) {
            var open by remember { mutableStateOf(false) }
            val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
            OutlinedButton(onClick = { open = true }) { Text("Show expanded sheet") }
            if (open) {
                ModalBottomSheet(onDismissRequest = { open = false }, sheetState = state) {
                    SheetBody()
                }
            }
        }
    }
}

@Composable
private fun SheetBody() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text("Sheet title", style = MaterialTheme.typography.titleLarge)
        repeat(8) { index ->
            Text(
                text = "Sheet row ${index + 1}",
                style = MaterialTheme.typography.bodyLarge,
                modifier = Modifier.padding(vertical = 8.dp),
            )
        }
    }
}
