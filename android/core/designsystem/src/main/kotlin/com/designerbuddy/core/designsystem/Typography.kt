package com.designerbuddy.core.designsystem

import androidx.compose.material3.Typography
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight

/**
 * Roboto Flex (OFL) — variable font instanced per weight via variation
 * settings. Stands in for NoiGrotesk until its Android license is confirmed;
 * swap happens only in this file.
 */
val RobotoFlex = FontFamily(
    Font(
        R.font.roboto_flex,
        weight = FontWeight.Normal,
        variationSettings = FontVariation.Settings(FontVariation.weight(400)),
    ),
    Font(
        R.font.roboto_flex,
        weight = FontWeight.Medium,
        variationSettings = FontVariation.Settings(FontVariation.weight(500)),
    ),
    Font(
        R.font.roboto_flex,
        weight = FontWeight.SemiBold,
        variationSettings = FontVariation.Settings(FontVariation.weight(600)),
    ),
    Font(
        R.font.roboto_flex,
        weight = FontWeight.Bold,
        variationSettings = FontVariation.Settings(FontVariation.weight(700)),
    ),
)

/** Chivo Mono (OFL) — code samples and numeric readouts, matching iOS. */
val ChivoMono = FontFamily(
    Font(
        R.font.chivo_mono,
        weight = FontWeight.Normal,
        variationSettings = FontVariation.Settings(FontVariation.weight(400)),
    ),
    Font(
        R.font.chivo_mono,
        weight = FontWeight.Medium,
        variationSettings = FontVariation.Settings(FontVariation.weight(500)),
    ),
)

private val defaults = Typography()

/** M3 type scale with the brand family swapped in. */
val AppTypography = Typography(
    displayLarge = defaults.displayLarge.copy(fontFamily = RobotoFlex),
    displayMedium = defaults.displayMedium.copy(fontFamily = RobotoFlex),
    displaySmall = defaults.displaySmall.copy(fontFamily = RobotoFlex),
    headlineLarge = defaults.headlineLarge.copy(fontFamily = RobotoFlex),
    headlineMedium = defaults.headlineMedium.copy(fontFamily = RobotoFlex),
    headlineSmall = defaults.headlineSmall.copy(fontFamily = RobotoFlex),
    titleLarge = defaults.titleLarge.copy(fontFamily = RobotoFlex),
    titleMedium = defaults.titleMedium.copy(fontFamily = RobotoFlex),
    titleSmall = defaults.titleSmall.copy(fontFamily = RobotoFlex),
    bodyLarge = defaults.bodyLarge.copy(fontFamily = RobotoFlex),
    bodyMedium = defaults.bodyMedium.copy(fontFamily = RobotoFlex),
    bodySmall = defaults.bodySmall.copy(fontFamily = RobotoFlex),
    labelLarge = defaults.labelLarge.copy(fontFamily = RobotoFlex),
    labelMedium = defaults.labelMedium.copy(fontFamily = RobotoFlex),
    labelSmall = defaults.labelSmall.copy(fontFamily = RobotoFlex),
)
