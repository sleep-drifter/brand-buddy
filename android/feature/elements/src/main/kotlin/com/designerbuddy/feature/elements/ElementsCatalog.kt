package com.designerbuddy.feature.elements

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CallToAction
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material.icons.automirrored.filled.List
import androidx.compose.material.icons.automirrored.filled.Label
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.RunCircle
import androidx.compose.material.icons.filled.ViewWeek
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
        icon = Icons.AutoMirrored.Filled.Label,
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
    AppEntry(
        id = "elements/sheets",
        name = "Bottom Sheets",
        section = "Overlays",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.CallToAction,
        keywords = listOf("modal", "detent", "drawer"),
        content = { SheetsScreen() },
    ),
    AppEntry(
        id = "elements/snackbars",
        name = "Snackbars",
        section = "Indicators",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.Notifications,
        keywords = listOf("toast", "banner", "undo"),
        content = { SnackbarsScreen() },
    ),
    AppEntry(
        id = "elements/segmented-buttons",
        name = "Segmented Buttons",
        section = "Selection",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.ViewWeek,
        keywords = listOf("segmented control", "single choice", "multi choice"),
        content = { SegmentedButtonsScreen() },
    ),
    AppEntry(
        id = "elements/lists",
        name = "Lists & Swipeable Rows",
        section = "Layout",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.AutoMirrored.Filled.List,
        keywords = listOf("rows", "swipe", "dismiss", "dividers"),
        content = { ListsScreen() },
    ),
    AppEntry(
        id = "elements/date-time-pickers",
        name = "Date & Time Pickers",
        section = "Inputs & Forms",
        group = CatalogGroup.ELEMENTS,
        icon = Icons.Filled.DateRange,
        keywords = listOf("calendar", "clock", "dialog"),
        content = { DateTimePickersScreen() },
    ),
)
