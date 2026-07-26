package com.designerbuddy.android

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Modifier
import androidx.navigation3.runtime.entry
import androidx.navigation3.runtime.entryProvider
import androidx.navigation3.ui.NavDisplay
import com.designerbuddy.core.catalog.AppEntry
import com.designerbuddy.core.catalog.CatalogRegistry
import com.designerbuddy.core.data.PinsRepository
import com.designerbuddy.feature.elements.elementsEntries
import com.designerbuddy.feature.home.HomeScreen
import kotlinx.coroutines.launch

/** Aggregated catalog. Each feature module contributes its entry list here. */
val catalogRegistry: CatalogRegistry by lazy {
    CatalogRegistry(
        buildList {
            addAll(elementsEntries)
        },
    )
}

/** Nav keys. Plain classes for now — swapping to @Serializable NavKeys (for
 * process-death restoration via rememberNavBackStack) once the serialization
 * plugin story on AGP built-in Kotlin is settled. */
data object HomeKey
data class EntryKey(val id: String)

@Composable
fun DesignerBuddyApp(pinsRepository: PinsRepository) {
    val backStack = remember { mutableStateListOf<Any>(HomeKey) }
    val pinnedIds by pinsRepository.pinnedIds.collectAsState(initial = emptySet())
    val scope = rememberCoroutineScope()

    NavDisplay(
        backStack = backStack,
        onBack = { backStack.removeLastOrNull() },
        entryProvider = entryProvider {
            entry<HomeKey> {
                HomeScreen(
                    registry = catalogRegistry,
                    pinnedIds = pinnedIds,
                    onTogglePin = { entry -> scope.launch { pinsRepository.toggle(entry.id) } },
                    onOpen = { entry -> backStack.add(EntryKey(entry.id)) },
                )
            }
            entry<EntryKey> { key ->
                val entry = catalogRegistry.entry(key.id)
                if (entry != null) {
                    DemoHost(entry = entry, onBack = { backStack.removeLastOrNull() })
                } else {
                    // Stale key (entry removed) — nothing to show.
                    Box(Modifier.fillMaxSize())
                }
            }
        },
    )
}

/** Chrome around a catalog page: title bar + back, content owns the rest. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DemoHost(entry: AppEntry, onBack: () -> Unit) {
    Scaffold(
        modifier = Modifier.fillMaxSize(),
        topBar = {
            TopAppBar(
                title = { Text(entry.name) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
            )
        },
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            entry.content()
        }
    }
}
