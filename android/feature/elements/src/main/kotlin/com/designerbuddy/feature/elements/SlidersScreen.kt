package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RangeSlider
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.ChivoMono
import com.designerbuddy.core.designsystem.demoSection
import kotlin.math.roundToInt

@Composable
fun SlidersScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(title = "Continuous") {
            var value by remember { mutableFloatStateOf(0.4f) }
            ValueReadout((value * 100).roundToInt().toString())
            Slider(value = value, onValueChange = { value = it })
        }

        demoSection(title = "Stepped", description = "10 discrete steps.") {
            var value by remember { mutableFloatStateOf(40f) }
            ValueReadout(value.roundToInt().toString())
            Slider(
                value = value,
                onValueChange = { value = it },
                valueRange = 0f..100f,
                steps = 9,
            )
        }

        demoSection(title = "Range") {
            var range by remember { mutableStateOf(20f..80f) }
            ValueReadout(
                "${range.start.roundToInt()} – ${range.endInclusive.roundToInt()}",
            )
            RangeSlider(
                value = range,
                onValueChange = { range = it },
                valueRange = 0f..100f,
            )
        }

        demoSection(title = "Disabled") {
            Slider(value = 0.6f, onValueChange = {}, enabled = false)
        }
    }
}

@Composable
private fun ValueReadout(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.labelLarge.copy(fontFamily = ChivoMono),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}
