package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ContainedLoadingIndicator
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.LoadingIndicator
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

/** M3 Expressive loading indicators: morphing MaterialShapes polygons. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun LoadingIndicatorsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Loading indicator",
            description = "The expressive replacement for the plain spinner — a polygon that morphs between shapes as it spins.",
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(24.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                LoadingIndicator()
            }
        }

        demoSection(
            title = "Contained",
            description = "On a surface, for placement over content.",
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(24.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                ContainedLoadingIndicator()
            }
        }

        demoSection(
            title = "Determinate",
            description = "Progress drives the morph — drag the slider.",
        ) {
            var progress by remember { mutableFloatStateOf(0.6f) }
            Row(
                horizontalArrangement = Arrangement.spacedBy(24.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                LoadingIndicator(progress = { progress })
                ContainedLoadingIndicator(progress = { progress })
            }
            Slider(value = progress, onValueChange = { progress = it })
        }
    }
}
