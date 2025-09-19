package com.evenreality.g1app.hud

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.example.demo_ai_even.databinding.HudOverlayBinding
import com.example.demo_ai_even.R

/**
 * Lightweight helper that attaches the HUD preview layout to the provided [container]
 * and exposes a [render] method so native code can keep the preview in sync with Flutter.
 */
class HudOverlay(
    context: Context,
    private val container: ViewGroup,
) {
    private val binding = HudOverlayBinding.inflate(LayoutInflater.from(context), container, true)

    /**
     * Update the overlay UI using the latest [state].
     */
    fun render(state: HudOverlayState) {
        val hasText = !state.text.isNullOrBlank()
        val shouldShow = state.isActive && hasText

        val visibility = if (shouldShow) View.VISIBLE else View.GONE
        container.visibility = visibility
        binding.root.visibility = visibility

        if (!shouldShow) {
            binding.hudMessage.text = ""
            binding.pageIndicator.visibility = View.GONE
            binding.countdown.visibility = View.GONE
            return
        }

        binding.hudMessage.text = state.text

        val pageText = state.pageIndicator
        binding.pageIndicator.text = pageText
        binding.pageIndicator.visibility = if (pageText.isNullOrBlank()) View.GONE else View.VISIBLE

        val countdown = state.countdownSeconds
        when {
            countdown != null && countdown > 0 -> {
                binding.countdown.text = container.context.getString(R.string.hud_overlay_countdown, countdown)
                binding.countdown.visibility = View.VISIBLE
            }
            state.isManualMode -> {
                binding.countdown.text = container.context.getString(R.string.hud_overlay_manual)
                binding.countdown.visibility = View.VISIBLE
            }
            else -> {
                binding.countdown.text = ""
                binding.countdown.visibility = View.GONE
            }
        }
    }
}
