package com.designerbuddy.core.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.pinsDataStore: DataStore<Preferences> by preferencesDataStore(name = "pins")

private val PINNED_IDS = stringSetPreferencesKey("pinned_entry_ids")

/**
 * Bookmarked catalog entries, keyed by [AppEntry.id]. DataStore-backed —
 * the Android analog of the iOS PinsStore's @AppStorage set.
 */
class PinsRepository(private val context: Context) {

    val pinnedIds: Flow<Set<String>> =
        context.pinsDataStore.data.map { prefs -> prefs[PINNED_IDS] ?: emptySet() }

    suspend fun toggle(id: String) {
        context.pinsDataStore.edit { prefs ->
            val current = prefs[PINNED_IDS] ?: emptySet()
            prefs[PINNED_IDS] = if (id in current) current - id else current + id
        }
    }
}
