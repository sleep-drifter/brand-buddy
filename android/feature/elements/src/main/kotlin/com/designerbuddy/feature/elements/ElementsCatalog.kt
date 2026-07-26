package com.designerbuddy.feature.elements

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Label
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.RunCircle
import androidx.compose.material.icons.filled.SmartButton
import androidx.compose.material.icons.filled.Style
import androidx.compose.material.icons.filled.TextFields
import androidx.compose.material.icons.filled.ToggleOn
import androidx.compose.material.icons.filled.Tune
import com.designerbuddy.core.catalog.AppEntry
import com.designerbuddy.core.catalog.CatalogGroup

/** This module's contribution to the catalog, aggregated by :app. */
val elementsEntries: List<AppEntry> = listOf(
    AppEntry(
        id = "elements/buttons",
        name = "Buttons",
        section = "Actions",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.SmartButton,
        keywords = listOf("cta", "fab", "filled", "tonal", "outlined"),
        content = { ButtonsScreen() },
    ),
    AppEntry(
        id = "elements/toggles",
        name = "Toggles & Selection",
        section = "Selection",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.ToggleOn,
        keywords = listOf("switch", "checkbox", "radio"),
        content = { TogglesScreen() },
    ),
    AppEntry(
        id = "elements/sliders",
        name = "Sliders",
        section = "Inputs & Forms",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.Tune,
        keywords = listOf("range", "stepper", "value"),
        content = { SlidersScreen() },
    ),
    AppEntry(
        id = "elements/text-fields",
        name = "Text Fields",
        section = "Inputs & Forms",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.TextFields,
        keywords = listOf("input", "form", "outlined", "password"),
        content = { TextFieldsScreen() },
    ),
    AppEntry(
        id = "elements/cards",
        name = "Cards",
        section = "Layout",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.Style,
        keywords = listOf("container", "elevated", "outlined"),
        content = { CardsScreen() },
    ),
    AppEntry(
        id = "elements/progress",
        name = "Progress Indicators",
        section = "Indicators",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.RunCircle,
        keywords = listOf("loading", "spinner", "determinate"),
        content = { ProgressScreen() },
    ),
    AppEntry(
        id = "elements/chips",
        name = "Chips & Badges",
        section = "Indicators",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.Label,
        keywords = listOf("tag", "filter", "assist", "count"),
        content = { ChipsScreen() },
    ),
    AppEntry(
        id = "elements/dialogs",
        name = "Alerts & Dialogs",
        section = "Overlays",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.CheckCircle,
        keywords = listOf("alert", "confirm", "modal"),
        content = { DialogsScreen() },
    ),
    AppEntry(
        id = "elements/menus",
        name = "Menus",
        section = "Overlays",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.MoreVert,
        keywords = listOf("dropdown", "context", "overflow"),
        content = { MenusScreen() },
    ),
)
