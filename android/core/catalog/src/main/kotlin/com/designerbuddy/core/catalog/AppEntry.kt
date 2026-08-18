package com.designerbuddy.core.catalog

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.vector.ImageVector

enum class CatalogGroup(val title: String) {
    EXPRESSIVE("Expressive"),
    ELEMENTS("Elements"),
    PATTERNS("Patterns & System"),
    SHADERS("Shaders"),
    PLAYGROUNDS("Playgrounds"),
}

/** Back-navigation callback for pages that own their whole screen
 * ([AppEntry.ownsChrome]); provided by the demo host. */
val LocalDemoBack = staticCompositionLocalOf<() -> Unit> { {} }

/**
 * One catalog page. Feature modules declare their entries; :app aggregates
 * them into the [CatalogRegistry]. (A KSP processor can generate the
 * aggregation later; explicit lists keep the build simple for now.)
 */
class AppEntry(
    /** Stable id, e.g. "elements/buttons" — used as nav key and pin key. */
    val id: String,
    val name: String,
    /** Section within the group, e.g. "Actions", "Inputs & Forms". */
    val section: String,
    val group: CatalogGroup,
    val icon: ImageVector,
    val keywords: List<String> = emptyList(),
    /** True when the page renders its own Scaffold/app bar (e.g. app-bar
     * demos); the host then provides no chrome, only [LocalDemoBack]. */
    val ownsChrome: Boolean = false,
    val content: @Composable () -> Unit,
) {
    val nameLower: String = name.lowercase()
    val sectionLower: String = section.lowercase()
    val keywordsLower: List<String> = keywords.map { it.lowercase() }
}

class CatalogRegistry(val all: List<AppEntry>) {
    private val byId = all.associateBy { it.id }

    fun entry(id: String): AppEntry? = byId[id]

    fun group(group: CatalogGroup): List<AppEntry> = all.filter { it.group == group }

    /** Same matching behavior as the iOS app: in-order fuzzy over name and
     * section, exact contains over keywords. */
    fun search(rawQuery: String): List<AppEntry> {
        val q = rawQuery.trim().lowercase()
        if (q.isEmpty()) return emptyList()
        return all.filter { entry ->
            fuzzyMatch(q, entry.nameLower) ||
                fuzzyMatch(q, entry.sectionLower) ||
                entry.keywordsLower.any { it.contains(q) }
        }
    }
}

/** True when every char of [query] appears in [target] in order. */
fun fuzzyMatch(query: String, target: String): Boolean {
    if (query.isEmpty()) return true
    var qi = 0
    for (ch in target) {
        if (ch == query[qi]) {
            qi++
            if (qi == query.length) return true
        }
    }
    return false
}
