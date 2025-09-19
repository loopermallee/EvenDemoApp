package com.evenreality.g1app.hud

/**
 * Represents the data that should be rendered inside the HUD preview overlay.
 */
data class HudOverlayState(
    val isActive: Boolean,
    val text: String?,
    val pageIndicator: String?,
    val countdownSeconds: Int?,
    val isManualMode: Boolean
) {
    companion object {
        val Hidden = HudOverlayState(
            isActive = false,
            text = null,
            pageIndicator = null,
            countdownSeconds = null,
            isManualMode = false,
        )

        fun fromMap(raw: Map<*, *>?): HudOverlayState {
            if (raw == null) return Hidden

            val isActive = raw["isActive"] as? Boolean ?: false
            val text = raw["text"] as? String
            val pageIndicator = raw["page"] as? String
            val isManual = raw["isManual"] as? Boolean ?: false

            val countdownValue = raw["countdown"] ?: raw["countdownSeconds"]
            val countdownSeconds = when (countdownValue) {
                is Number -> countdownValue.toInt()
                is String -> countdownValue.toIntOrNull()
                else -> null
            }

            return HudOverlayState(
                isActive = isActive,
                text = text,
                pageIndicator = pageIndicator,
                countdownSeconds = countdownSeconds,
                isManualMode = isManual,
            )
        }
    }
}
