package com.designerbuddy.feature.elements

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Card
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedCard
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.designerbuddy.core.designsystem.demoSection

@Composable
fun CardsScreen() {
    LazyColumn(
        modifier = Modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
    ) {
        demoSection(
            title = "Card types",
            description = "Filled, elevated, and outlined containers.",
        ) {
            Card(modifier = Modifier.fillMaxWidth(), onClick = {}) {
                CardBody("Filled card", "Default container for related content.")
            }
            ElevatedCard(modifier = Modifier.fillMaxWidth(), onClick = {}) {
                CardBody("Elevated card", "Shadow separates it from the background.")
            }
            OutlinedCard(modifier = Modifier.fillMaxWidth(), onClick = {}) {
                CardBody("Outlined card", "Border for high-emphasis boundaries.")
            }
        }
    }
}

@Composable
private fun CardBody(title: String, subtitle: String) {
    Column(modifier = Modifier.padding(16.dp)) {
        Text(title, style = MaterialTheme.typography.titleMedium)
        Text(
            subtitle,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp),
        )
    }
}
