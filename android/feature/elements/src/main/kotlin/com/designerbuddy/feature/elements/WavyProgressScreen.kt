package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.CircularWavyProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LinearWavyProgressIndicator
import androidx.compose.material3.Slider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/** M3 Expressive wavy progress — the squiggle. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun WavyProgressScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Indeterminate",
            description = "The wave travels while waiting.",
        ) {
            LinearWavyProgressIndicator(modifier = Modifier.fillMaxWidth())
            Row(
                horizontalArrangement = Arrangement.spacedBy(24.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircularWavyProgressIndicator()
            }
        }

        demoSection(
            title = "Determinate",
            description = "The wave fills to the value; the remaining track stays flat. Drag to scrub.",
        ) {
            var progress by remember { mutableFloatStateOf(0.7f) }
            LinearWavyProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxWidth(),
            )
            Row(
                horizontalArrangement = Arrangement.spacedBy(24.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                CircularWavyProgressIndicator(progress = { progress })
            }
            Slider(value = progress, onValueChange = { progress = it })
        }
    }
}
