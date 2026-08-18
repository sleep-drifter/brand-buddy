package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Checkbox
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

@Composable
fun TogglesScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(title = "Switches") {
            var basic by remember { mutableStateOf(true) }
            LabeledRow("Basic") {
                Switch(checked = basic, onCheckedChange = { basic = it })
            }

            var withIcon by remember { mutableStateOf(true) }
            LabeledRow("With icon") {
                Switch(
                    checked = withIcon,
                    onCheckedChange = { withIcon = it },
                    thumbContent = if (withIcon) {
                        {
                            Icon(
                                Icons.Filled.Check,
                                contentDescription = null,
                                modifier = Modifier.size(SwitchDefaults.IconSize),
                            )
                        }
                    } else {
                        null
                    },
                )
            }

            LabeledRow("Disabled") {
                Switch(checked = true, onCheckedChange = {}, enabled = false)
            }
        }

        demoSection(title = "Checkboxes") {
            var checked by remember { mutableStateOf(true) }
            LabeledRow("Basic") {
                Checkbox(checked = checked, onCheckedChange = { checked = it })
            }
            LabeledRow("Disabled") {
                Checkbox(checked = false, onCheckedChange = {}, enabled = false)
            }
        }

        demoSection(title = "Radio buttons") {
            var selected by remember { mutableIntStateOf(0) }
            listOf("Option A", "Option B", "Option C").forEachIndexed { index, label ->
                LabeledRow(label) {
                    RadioButton(selected = selected == index, onClick = { selected = index })
                }
            }
        }
    }
}

@Composable
private fun LabeledRow(label: String, trailing: @Composable () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyLarge,
            modifier = Modifier.weight(1f),
        )
        trailing()
    }
}
