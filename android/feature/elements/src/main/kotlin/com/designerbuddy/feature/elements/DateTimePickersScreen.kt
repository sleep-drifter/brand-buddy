package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TimeInput
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
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
fun DateTimePickersScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Date picker dialog",
            description = "Modal calendar with input-mode toggle.",
        ) {
            var open by remember { mutableStateOf(false) }
            val state = rememberDatePickerState()
            OutlinedButton(onClick = { open = true }) { Text("Pick a date") }
            if (open) {
                DatePickerDialog(
                    onDismissRequest = { open = false },
                    confirmButton = {
                        TextButton(onClick = { open = false }) { Text("OK") }
                    },
                    dismissButton = {
                        TextButton(onClick = { open = false }) { Text("Cancel") }
                    },
                ) {
                    DatePicker(state = state)
                }
            }
        }

        demoSection(
            title = "Time input",
            description = "Keyboard-first time entry, inline.",
        ) {
            val state = rememberTimePickerState(initialHour = 9, initialMinute = 41)
            TimeInput(state = state)
        }
    }
}
