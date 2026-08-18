package com.designerbuddy.feature.elements

import androidx.compose.animation.core.FiniteAnimationSpec
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/**
 * The expressive MotionScheme: every M3 component animates with these spring
 * tokens instead of duration curves. Spatial springs (with bounce) move
 * things; effects springs (no bounce) fade and tint them.
 */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun MotionSchemeScreen() {
    var atEnd by remember { mutableStateOf(false) }
    val motion = MaterialTheme.motionScheme

    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Spatial springs",
            description = "Position/size/shape motion — expressive tuning overshoots and settles. Same distance, three speeds.",
        ) {
            SpringLane("Fast", motion.fastSpatialSpec(), atEnd)
            SpringLane("Default", motion.defaultSpatialSpec(), atEnd)
            SpringLane("Slow", motion.slowSpatialSpec(), atEnd)
        }

        demoSection(
            title = "Effects springs",
            description = "Color/opacity motion — never bounces, so fades stay clean.",
        ) {
            FadeLane("Fast", motion.fastEffectsSpec(), atEnd)
            FadeLane("Default", motion.defaultEffectsSpec(), atEnd)
            FadeLane("Slow", motion.slowEffectsSpec(), atEnd)
        }

        demoSection(title = "Run it") {
            Button(onClick = { atEnd = !atEnd }) {
                Text(if (atEnd) "Animate back" else "Animate")
            }
        }
    }
}

@Composable
private fun SpringLane(label: String, spec: FiniteAnimationSpec<Dp>, atEnd: Boolean) {
    val offset by animateDpAsState(
        targetValue = if (atEnd) 200.dp else 0.dp,
        animationSpec = spec,
        label = "spatial-$label",
    )
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            label,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(width = 64.dp, height = 20.dp),
        )
        Box(
            modifier = Modifier
                .offset(x = offset)
                .size(28.dp)
                .background(MaterialTheme.colorScheme.primary, CircleShape),
        )
    }
}

@Composable
private fun FadeLane(label: String, spec: FiniteAnimationSpec<Float>, atEnd: Boolean) {
    val alpha by animateFloatAsState(
        targetValue = if (atEnd) 0.15f else 1f,
        animationSpec = spec,
        label = "effects-$label",
    )
    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            label,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.size(width = 64.dp, height = 20.dp),
        )
        Box(
            modifier = Modifier
                .size(28.dp)
                .graphicsLayer { this.alpha = alpha }
                .background(MaterialTheme.colorScheme.tertiary, CircleShape),
        )
    }
}
