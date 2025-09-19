package com.example.demo_ai_even

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.demo_ai_even.bluetooth.BleConnectionState
import com.example.demo_ai_even.bluetooth.BleManager
import com.example.demo_ai_even.bluetooth.BleNotification
import com.example.demo_ai_even.model.BleDeviceSummary
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class BleUiState(
    val bluetoothEnabled: Boolean = true,
    val scanning: Boolean = false,
    val scanResults: List<BleDeviceSummary> = emptyList(),
    val connectionState: BleConnectionState = BleConnectionState.Idle,
    val logs: List<String> = emptyList(),
    val lastBleNotification: BleNotification? = null,
    val recentNotifications: List<NotificationEvent> = emptyList()
)

class BleViewModel(application: Application) : AndroidViewModel(application) {

    private val manager = BleManager.instance

    private val _uiState = MutableStateFlow(
        BleUiState(bluetoothEnabled = manager.isBluetoothEnabled())
    )
    val uiState: StateFlow<BleUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            combine(
                manager.scanResults,
                manager.isScanning,
                manager.connectionState
            ) { results, scanning, connection ->
                Triple(results, scanning, connection)
            }.collect { (results, scanning, connection) ->
                _uiState.update { state ->
                    state.copy(
                        scanResults = results,
                        scanning = scanning,
                        connectionState = connection,
                        bluetoothEnabled = manager.isBluetoothEnabled()
                    )
                }
            }
        }

        viewModelScope.launch {
            manager.logs.collect { message ->
                _uiState.update { state ->
                    state.copy(
                        logs = (state.logs + message).takeLast(MAX_LOGS)
                    )
                }
            }
        }

        viewModelScope.launch {
            manager.notifications.collect { notification ->
                _uiState.update { state ->
                    state.copy(lastBleNotification = notification)
                }
            }
        }

        viewModelScope.launch {
            NotificationBridge.events.collect { event ->
                _uiState.update { state ->
                    state.copy(
                        recentNotifications = (listOf(event) + state.recentNotifications)
                            .take(MAX_NOTIFICATIONS)
                    )
                }
            }
        }
    }

    fun refreshBluetoothState() {
        _uiState.update { it.copy(bluetoothEnabled = manager.isBluetoothEnabled()) }
    }

    fun startScan() = manager.startScan()

    fun stopScan() = manager.stopScan()

    fun connect(address: String) = manager.connectToGlass(address)

    fun disconnect() = manager.disconnectFromGlasses()

    fun ensureConnected() = manager.ensureConnected()

    fun sendHexCommand(hex: String): Boolean = manager.sendHexPayload(hex)

    fun reconnectLast(): Boolean = manager.reconnectLastDevice()

    companion object {
        private const val MAX_LOGS = 100
        private const val MAX_NOTIFICATIONS = 10
    }
}
