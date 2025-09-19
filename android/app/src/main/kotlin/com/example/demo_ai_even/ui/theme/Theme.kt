package com.example.demo_ai_even.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = PrimaryBlue,
    onPrimary = androidx.compose.ui.graphics.Color.White,
    secondary = SecondaryBlue,
    onSecondary = androidx.compose.ui.graphics.Color.Black,
    tertiary = AccentPurple
)

private val DarkColors = darkColorScheme(
    primary = SecondaryBlue,
    onPrimary = androidx.compose.ui.graphics.Color.Black,
    secondary = AccentPurple,
    onSecondary = androidx.compose.ui.graphics.Color.White,
    tertiary = PrimaryBlue,
    surface = DarkSurface,
    background = DarkSurface
)

@Composable
fun EvenDemoTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColors else LightColors

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        shapes = Shapes,
        content = content
    )
}
