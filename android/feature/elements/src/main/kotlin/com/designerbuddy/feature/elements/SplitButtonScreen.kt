package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3ExpressiveApi
import androidx.compose.material3.Icon
import androidx.compose.material3.SplitButtonDefaults
import androidx.compose.material3.SplitButtonLayout
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

/** M3 Expressive split button: primary action + attached menu trigger with
 * independently morphing inner corners. */
@OptIn(ExperimentalMaterial3ExpressiveApi::class)
@Composable
fun SplitButtonScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Filled",
            description = "The leading side performs the action; the trailing side opens options. Press either half — the inner corners morph independently.",
        ) {
            Box {
                var menuOpen by remember { mutableStateOf(false) }
                SplitButtonLayout(
                    leadingButton = {
                        SplitButtonDefaults.LeadingButton(onClick = {}) {
                            Icon(
                                Icons.AutoMirrored.Filled.Send,
                                contentDescription = null,
                                modifier = Modifier.size(SplitButtonDefaults.LeadingIconSize),
                            )
                            Spacer(Modifier.width(8.dp))
                            Text("Send")
                        }
                    },
                    trailingButton = {
                        SplitButtonDefaults.TrailingButton(onClick = { menuOpen = true }) {
                            Icon(
                                Icons.Filled.KeyboardArrowDown,
                                contentDescription = "More send options",
                                modifier = Modifier.size(SplitButtonDefaults.TrailingIconSize),
                            )
                        }
                    },
                )
                DropdownMenu(expanded = menuOpen, onDismissRequest = { menuOpen = false }) {
                    listOf("Send later", "Send + archive", "Save draft").forEach { label ->
                        DropdownMenuItem(text = { Text(label) }, onClick = { menuOpen = false })
                    }
                }
            }
        }

        demoSection(title = "Tonal & outlined") {
            SplitButtonLayout(
                leadingButton = {
                    SplitButtonDefaults.TonalLeadingButton(onClick = {}) { Text("Tonal") }
                },
                trailingButton = {
                    SplitButtonDefaults.TonalTrailingButton(onClick = {}) {
                        Icon(
                            Icons.Filled.KeyboardArrowDown,
                            contentDescription = null,
                            modifier = Modifier.size(SplitButtonDefaults.TrailingIconSize),
                        )
                    }
                },
            )
            SplitButtonLayout(
                leadingButton = {
                    SplitButtonDefaults.OutlinedLeadingButton(onClick = {}) { Text("Outlined") }
                },
                trailingButton = {
                    SplitButtonDefaults.OutlinedTrailingButton(onClick = {}) {
                        Icon(
                            Icons.Filled.KeyboardArrowDown,
                            contentDescription = null,
                            modifier = Modifier.size(SplitButtonDefaults.TrailingIconSize),
                        )
                    }
                },
            )
        }
    }
}
