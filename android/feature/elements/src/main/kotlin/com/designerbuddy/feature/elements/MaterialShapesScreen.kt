package com.designerbuddy.feature.elements

import androidx.compose.animation.animateContentSize
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialShapes
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.toShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/** The M3 Expressive shape library — the same polygons the loading
 * indicator morphs through, usable as any component's shape. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class, ExperimentalLayoutApi::class)
@Composable
fun MaterialShapesScreen() {
    val shapes = remember {
        listOf(
            "Circle" to MaterialShapes.Circle,
            "Square" to MaterialShapes.Square,
            "Slanted" to MaterialShapes.Slanted,
            "Arch" to MaterialShapes.Arch,
            "Fan" to MaterialShapes.Fan,
            "Arrow" to MaterialShapes.Arrow,
            "Semicircle" to MaterialShapes.SemiCircle,
            "Oval" to MaterialShapes.Oval,
            "Pill" to MaterialShapes.Pill,
            "Triangle" to MaterialShapes.Triangle,
            "Diamond" to MaterialShapes.Diamond,
            "Clam shell" to MaterialShapes.ClamShell,
            "Pentagon" to MaterialShapes.Pentagon,
            "Gem" to MaterialShapes.Gem,
            "Sunny" to MaterialShapes.Sunny,
            "Very sunny" to MaterialShapes.VerySunny,
            "Cookie 4" to MaterialShapes.Cookie4Sided,
            "Cookie 6" to MaterialShapes.Cookie6Sided,
            "Cookie 7" to MaterialShapes.Cookie7Sided,
            "Cookie 9" to MaterialShapes.Cookie9Sided,
            "Cookie 12" to MaterialShapes.Cookie12Sided,
            "Clover 4" to MaterialShapes.Clover4Leaf,
            "Clover 8" to MaterialShapes.Clover8Leaf,
            "Burst" to MaterialShapes.Burst,
            "Soft burst" to MaterialShapes.SoftBurst,
            "Boom" to MaterialShapes.Boom,
            "Soft boom" to MaterialShapes.SoftBoom,
            "Flower" to MaterialShapes.Flower,
            "Puffy" to MaterialShapes.Puffy,
            "Puffy diamond" to MaterialShapes.PuffyDiamond,
            "Ghost-ish" to MaterialShapes.Ghostish,
            "Bun" to MaterialShapes.Bun,
            "Heart" to MaterialShapes.Heart,
        )
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Hero",
            description = "Any of these can be a Surface shape, an avatar mask, an icon container…",
        ) {
            var index by remember { mutableIntStateOf(14) } // Sunny
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .animateContentSize(),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Surface(
                    shape = shapes[index].second.toShape(),
                    color = MaterialTheme.colorScheme.primaryContainer,
                    modifier = Modifier.size(160.dp),
                ) {}
                Text(shapes[index].first, style = MaterialTheme.typography.titleMedium)
                OutlinedButton(onClick = { index = (index + 1) % shapes.size }) {
                    Text("Next shape")
                }
            }
        }

        demoSection(title = "The full library") {
            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                shapes.forEach { (_, polygon) ->
                    Box {
                        Surface(
                            shape = polygon.toShape(),
                            color = MaterialTheme.colorScheme.secondaryContainer,
                            modifier = Modifier.size(52.dp),
                        ) {}
                    }
                }
            }
        }
    }
}
