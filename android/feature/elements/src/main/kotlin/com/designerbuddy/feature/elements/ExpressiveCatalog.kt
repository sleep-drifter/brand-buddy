package com.designerbuddy.feature.elements

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddCircle
import androidx.compose.material.icons.filled.Animation
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CallSplit
import androidx.compose.material.icons.filled.Category
import androidx.compose.material.icons.filled.RadioButtonChecked
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.ViewColumn
import androidx.compose.material.icons.filled.Waves
import androidx.compose.material.icons.filled.WebAsset
import com.designerbuddy.core.catalog.AppEntry
import com.designerbuddy.core.catalog.CatalogGroup

/**
 * Material 3 Expressive showcase — the components and systems introduced
 * with the expressive design language (material3 1.5 alphas).
 */
val expressiveEntries: List<AppEntry> = listOf(
    AppEntry(
        id = "expressive/loading-indicators",
        name = "Loading Indicators",
        section = "Progress & Loading",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.Refresh,
        keywords = listOf("spinner", "morph", "shapes", "expressive"),
        content = { LoadingIndicatorsScreen() },
    ),
    AppEntry(
        id = "expressive/wavy-progress",
        name = "Wavy Progress",
        section = "Progress & Loading",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.Waves,
        keywords = listOf("squiggle", "linear", "circular", "expressive"),
        content = { WavyProgressScreen() },
    ),
    AppEntry(
        id = "expressive/fab-menu",
        name = "FAB Menu",
        section = "Actions",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.AddCircle,
        keywords = listOf("floating action button", "speed dial", "expressive"),
        content = { FabMenuScreen() },
    ),
    AppEntry(
        id = "expressive/toggle-buttons",
        name = "Toggle Buttons",
        section = "Actions",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.RadioButtonChecked,
        keywords = listOf("shape morph", "checked", "expressive"),
        content = { ToggleButtonsScreen() },
    ),
    AppEntry(
        id = "expressive/button-groups",
        name = "Button Groups",
        section = "Actions",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.ViewColumn,
        keywords = listOf("squeeze", "connected", "segmented", "expressive"),
        content = { ButtonGroupsScreen() },
    ),
    AppEntry(
        id = "expressive/split-button",
        name = "Split Button",
        section = "Actions",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.CallSplit,
        keywords = listOf("dropdown", "combo", "expressive"),
        content = { SplitButtonScreen() },
    ),
    AppEntry(
        id = "expressive/floating-toolbar",
        name = "Floating Toolbar",
        section = "Navigation & Toolbars",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.Build,
        keywords = listOf("bottom bar", "actions", "expressive"),
        content = { FloatingToolbarScreen() },
    ),
    AppEntry(
        id = "expressive/flexible-app-bars",
        name = "Flexible App Bars",
        section = "Navigation & Toolbars",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.WebAsset,
        keywords = listOf("collapsing", "subtitle", "large title", "expressive"),
        ownsChrome = true,
        content = { FlexibleAppBarsScreen() },
    ),
    AppEntry(
        id = "expressive/material-shapes",
        name = "Material Shapes",
        section = "Foundations",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.Category,
        keywords = listOf("polygon", "cookie", "clover", "sunny", "morph"),
        content = { MaterialShapesScreen() },
    ),
    AppEntry(
        id = "expressive/motion-scheme",
        name = "Motion Scheme",
        section = "Foundations",
        group = CatalogGroup.EXPRESSIVE,
        icon = Icons.Filled.Animation,
        keywords = listOf("springs", "spatial", "effects", "physics"),
        content = { MotionSchemeScreen() },
    ),
)
