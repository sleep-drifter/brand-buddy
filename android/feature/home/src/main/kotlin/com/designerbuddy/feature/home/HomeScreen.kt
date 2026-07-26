package com.designerbuddy.feature.home

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.defaultMinSize
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.KeyboardArrowRight
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.ListItemDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.catalog.AppEntry
import com.designerbuddy.core.catalog.CatalogGroup
import com.designerbuddy.core.catalog.CatalogRegistry

/**
 * Home: grouped section previews + full catalog + fuzzy search, mirroring the
 * iOS app's structure. Bookmarking via long-press with haptic, like iOS.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    registry: CatalogRegistry,
    pinnedIds: Set<String>,
    onTogglePin: (AppEntry) -> Unit,
    onOpen: (AppEntry) -> Unit,
) {
    var query by rememberSaveable { mutableStateOf("") }
    val results = remember(query, registry) { registry.search(query) }
    val scrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

    Scaffold(
        modifier = Modifier
            .fillMaxSize()
            .nestedScroll(scrollBehavior.nestedScrollConnection),
        topBar = {
            TopAppBar(
                title = { Text("Designer Buddy") },
                scrollBehavior = scrollBehavior,
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item(key = "search") {
                OutlinedTextField(
                    value = query,
                    onValueChange = { query = it },
                    modifier = Modifier.fillMaxWidth(),
                    placeholder = { Text("Find something specific") },
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                    trailingIcon = {
                        if (query.isNotEmpty()) {
                            IconButton(onClick = { query = "" }) {
                                Icon(Icons.Filled.Clear, contentDescription = "Clear search")
                            }
                        }
                    },
                    singleLine = true,
                    shape = MaterialTheme.shapes.large,
                )
            }

            if (query.isEmpty()) {
                val saved = registry.all.filter { it.id in pinnedIds }
                if (saved.isNotEmpty()) {
                    item(key = "header:saved") {
                        SectionHeader("Saved")
                    }
                    items(saved.size, key = { "saved:${saved[it].id}" }) { index ->
                        val entry = saved[index]
                        CatalogRow(
                            entry = entry,
                            isPinned = true,
                            onClick = { onOpen(entry) },
                            onLongClick = { onTogglePin(entry) },
                        )
                    }
                }

                for (group in CatalogGroup.entries) {
                    val entries = registry.group(group)
                    if (entries.isEmpty()) continue

                    item(key = "header:${group.name}") {
                        SectionHeader(group.title)
                    }
                    val preview = entries.take(6)
                    items(
                        count = (preview.size + 1) / 2,
                        key = { row -> "grid:${group.name}:$row" },
                    ) { row ->
                        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                            for (col in 0..1) {
                                val entry = preview.getOrNull(row * 2 + col)
                                if (entry != null) {
                                    Box(modifier = Modifier.weight(1f)) {
                                        EntryGridCard(
                                            entry = entry,
                                            isPinned = entry.id in pinnedIds,
                                            onClick = { onOpen(entry) },
                                            onLongClick = { onTogglePin(entry) },
                                        )
                                    }
                                } else {
                                    Box(modifier = Modifier.weight(1f)) {}
                                }
                            }
                        }
                    }
                }

                item(key = "header:catalog") {
                    SectionHeader("Full catalog")
                }
                items(registry.all.size, key = { "row:${registry.all[it].id}" }) { index ->
                    val entry = registry.all[index]
                    CatalogRow(
                        entry = entry,
                        isPinned = entry.id in pinnedIds,
                        onClick = { onOpen(entry) },
                        onLongClick = { onTogglePin(entry) },
                    )
                }
            } else if (results.isEmpty()) {
                item(key = "empty") {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 48.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Icon(
                            Icons.Outlined.SearchOff,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                        Text(
                            text = "No results for “$query”",
                            style = MaterialTheme.typography.bodyLarge,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.padding(top = 12.dp),
                        )
                    }
                }
            } else {
                items(results.size, key = { "result:${results[it].id}" }) { index ->
                    val entry = results[index]
                    CatalogRow(
                        entry = entry,
                        isPinned = entry.id in pinnedIds,
                        onClick = { onOpen(entry) },
                        onLongClick = { onTogglePin(entry) },
                    )
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleLarge,
            modifier = Modifier.weight(1f),
        )
        Icon(
            Icons.AutoMirrored.Filled.KeyboardArrowRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun EntryGridCard(
    entry: AppEntry,
    isPinned: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
) {
    val haptics = LocalHapticFeedback.current
    Surface(
        shape = MaterialTheme.shapes.large,
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Box(
            modifier = Modifier.combinedClickable(
                onClick = onClick,
                onLongClick = {
                    haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    onLongClick()
                },
            ),
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .defaultMinSize(minHeight = 100.dp)
                    .padding(horizontal = 8.dp, vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(10.dp, Alignment.CenterVertically),
            ) {
                Icon(entry.icon, contentDescription = null)
                Text(
                    text = entry.name,
                    style = MaterialTheme.typography.labelMedium,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                )
            }
            if (isPinned) {
                Icon(
                    Icons.Filled.Bookmark,
                    contentDescription = "Bookmarked",
                    tint = MaterialTheme.colorScheme.primary,
                    modifier = Modifier
                        .align(Alignment.TopEnd)
                        .padding(6.dp),
                )
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun CatalogRow(
    entry: AppEntry,
    isPinned: Boolean,
    onClick: () -> Unit,
    onLongClick: () -> Unit,
) {
    val haptics = LocalHapticFeedback.current
    Surface(
        shape = MaterialTheme.shapes.large,
        color = MaterialTheme.colorScheme.surfaceContainer,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Box(
            modifier = Modifier.combinedClickable(
                onClick = onClick,
                onLongClick = {
                    haptics.performHapticFeedback(HapticFeedbackType.LongPress)
                    onLongClick()
                },
            ),
        ) {
            ListItem(
                headlineContent = { Text(entry.name) },
                supportingContent = { Text(entry.section) },
                leadingContent = { Icon(entry.icon, contentDescription = null) },
                trailingContent = {
                    if (isPinned) {
                        Icon(
                            Icons.Filled.Bookmark,
                            contentDescription = "Bookmarked",
                            tint = MaterialTheme.colorScheme.primary,
                        )
                    }
                },
                colors = ListItemDefaults.colors(containerColor = MaterialTheme.colorScheme.surfaceContainer),
            )
        }
    }
}
