package com.example.demo_ai_even.speech

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

class SpeechBridge {

    companion object {
        private const val REQ_RECORD_AUDIO = 1011

        private var speechRecognizer: SpeechRecognizer? = null
        private var recognizerIntent = android.content.Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }

        private var isListening = false
        private var onResult: ((text: String?, isFinal: Boolean) -> Unit)? = null

        fun init(activity: Activity, onResultCallback: (String?, Boolean) -> Unit) {
            onResult = onResultCallback
            if (speechRecognizer == null) {
                speechRecognizer = SpeechRecognizer.createSpeechRecognizer(activity)
                speechRecognizer?.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}
                    override fun onError(error: Int) {
                        isListening = false
                        // You could forward errors if needed
                    }
                    override fun onResults(results: Bundle?) {
                        isListening = false
                        val data = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = data?.firstOrNull()
                        onResult?.invoke(text ?: "", true)
                    }
                    override fun onPartialResults(partialResults: Bundle?) {
                        val data = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                        val text = data?.firstOrNull()
                        if (!text.isNullOrEmpty()) {
                            onResult?.invoke(text, false)
                        }
                    }
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })
            }
        }

        fun start(activity: Activity, done: (ok: Boolean, err: String?) -> Unit) {
            ensureAudioPermission(activity) { granted ->
                if (!granted) {
                    done(false, "Microphone permission denied")
                    return@ensureAudioPermission
                }
                if (!SpeechRecognizer.isRecognitionAvailable(activity)) {
                    done(false, "Speech recognition not available")
                    return@ensureAudioPermission
                }
                if (isListening) {
                    done(true, null)
                    return@ensureAudioPermission
                }
                init(activity) { text, isFinal ->
                    onResult?.invoke(text, isFinal)
                }
                isListening = true
                speechRecognizer?.startListening(recognizerIntent)
                done(true, null)
            }
        }

        fun stop(finalize: Boolean) {
            if (!isListening && speechRecognizer == null) return
            try {
                if (finalize) speechRecognizer?.stopListening() else speechRecognizer?.cancel()
            } catch (_: Exception) { }
            if (!finalize) isListening = false
        }

        private fun ensureAudioPermission(activity: Activity, cb: (Boolean) -> Unit) {
            val granted = ContextCompat.checkSelfPermission(activity, Manifest.permission.RECORD_AUDIO) ==
                    PackageManager.PERMISSION_GRANTED
            if (granted) {
                cb(true)
            } else {
                ActivityCompat.requestPermissions(activity, arrayOf(Manifest.permission.RECORD_AUDIO), REQ_RECORD_AUDIO)
                // We cannot synchronously know the result here. For simplicity, assume denied now;
                // MainActivity/Activity will get a callback; you can expand to handle it if needed.
                cb(false)
            }
        }
    }
}
