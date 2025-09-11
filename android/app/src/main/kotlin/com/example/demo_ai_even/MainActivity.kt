package com.example.demo_ai_even

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.os.SystemClock
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "MainActivitySTT"
        private const val REQ_RECORD_AUDIO = 1011
        private const val EVENT_SPEECH = "eventSpeechRecognize"
        private const val METHOD_SPEECH = "method.speech"
    }

    // ---- Speech state ----
    private var speechRecognizer: SpeechRecognizer? = null
    private var recognizerIntent: Intent? = null
    private var isListening = false
    private var speechEventsSink: EventChannel.EventSink? = null

    // ---- Throttle partials to reduce UI/BT load ----
    private var lastPartial = ""
    private var lastEmitUptime = 0L
    private val partialThrottleMs = 80L // fast but not spammy

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // EventChannel: Android → Flutter
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_SPEECH)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    speechEventsSink = events
                }
                override fun onCancel(arguments: Any?) {
                    speechEventsSink = null
                }
            })

        // MethodChannel: Flutter → Android
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_SPEECH)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> ensureAudioPermission(this) {
                        startListening()
                        result.success(true)
                    }
                    "stop" -> {
                        stopListening(finalize = true)
                        result.success(true)
                    }
                    "cancel" -> {
                        stopListening(finalize = false)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // -------- Permissions --------
    private fun ensureAudioPermission(activity: Activity, onGranted: () -> Unit) {
        val granted = ContextCompat.checkSelfPermission(
            activity, Manifest.permission.RECORD_AUDIO
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) {
            onGranted()
        } else {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                REQ_RECORD_AUDIO
            )
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_RECORD_AUDIO) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (granted) {
                startListening()
            } else {
                speechEventsSink?.error("perm_denied", "Microphone permission denied", null)
            }
        }
    }

    // -------- SpeechRecognizer setup --------
    private fun buildRecognizerIntent(): Intent {
        return Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
            putExtra(RecognizerIntent.EXTRA_CALLING_PACKAGE, packageName)

            // Make final result arrive quickly after you stop talking:
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 500)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 500)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 300)

            // Prefer offline if available (Android may ignore if unavailable):
            putExtra("android.speech.extra.PREFER_OFFLINE", true)
        }
    }

    private fun ensureRecognizer() {
        if (speechRecognizer == null) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
            speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                override fun onReadyForSpeech(params: Bundle?) { lastPartial = ""; lastEmitUptime = 0 }
                override fun onBeginningOfSpeech() {}
                override fun onRmsChanged(rmsdB: Float) {}
                override fun onBufferReceived(buffer: ByteArray?) {}
                override fun onEndOfSpeech() {}

                override fun onError(error: Int) {
                    Log.w(TAG, "onError: $error")
                    isListening = false
                    // Emit an empty final so Flutter flow can continue gracefully
                    speechEventsSink?.success(mapOf("script" to "", "isFinal" to true))
                }

                override fun onResults(results: Bundle?) {
                    isListening = false
                    val text = results
                        ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        ?.firstOrNull()
                        .orEmpty()
                    speechEventsSink?.success(mapOf("script" to text, "isFinal" to true))
                }

                override fun onPartialResults(partialResults: Bundle?) {
                    val text = partialResults
                        ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        ?.firstOrNull()
                        .orEmpty()
                    val now = SystemClock.uptimeMillis()
                    // Only emit if changed and we’re past throttle window
                    if (text.isNotEmpty() && text != lastPartial && now - lastEmitUptime >= partialThrottleMs) {
                        lastPartial = text
                        lastEmitUptime = now
                        speechEventsSink?.success(mapOf("script" to text, "isFinal" to false))
                    }
                }

                override fun onEvent(eventType: Int, params: Bundle?) {}
            })
        }
        if (recognizerIntent == null) {
            recognizerIntent = buildRecognizerIntent()
        }
    }

    private fun startListening() {
        if (isListening) return
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            speechEventsSink?.error("sr_unavailable", "Speech recognition not available", null)
            return
        }
        ensureRecognizer()
        isListening = true
        try {
            speechRecognizer?.startListening(recognizerIntent)
            // optional “started” signal
            speechEventsSink?.success(mapOf("script" to "", "isFinal" to false))
        } catch (e: Exception) {
            Log.e(TAG, "startListening failed", e)
            isListening = false
            speechEventsSink?.error("sr_start_fail", e.message, null)
        }
    }

    private fun stopListening(finalize: Boolean) {
        if (!isListening && speechRecognizer == null) return
        try {
            if (finalize) {
                speechRecognizer?.stopListening() // triggers onResults()
            } else {
                speechRecognizer?.cancel()
                speechEventsSink?.success(mapOf("script" to "", "isFinal" to true))
            }
        } catch (e: Exception) {
            Log.e(TAG, "stopListening failed", e)
        } finally {
            if (!finalize) isListening = false
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try { speechRecognizer?.destroy() } catch (_: Exception) {}
        speechRecognizer = null
        recognizerIntent = null
    }
}
