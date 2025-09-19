package com.example.demo_ai_even

import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bluetooth
import androidx.compose.material.icons.filled.PowerSettingsNew
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.ElevatedCard
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.example.demo_ai_even.bluetooth.BleConnectionState
import com.example.demo_ai_even.bluetooth.BleManager
import com.example.demo_ai_even.cpp.Cpp
import com.example.demo_ai_even.bluetooth.BlePermissionUtil
import com.example.demo_ai_even.bluetooth.BleNotification
import com.example.demo_ai_even.model.BleDeviceSummary
import com.example.demo_ai_even.ui.theme.EvenDemoTheme
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private val viewModel: BleViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Cpp.init()
        BleManager.instance.initBluetooth(this)

        @OptIn(ExperimentalMaterial3Api::class)
        setContent {
            EvenDemoTheme {
                val snackbarHostState = remember { SnackbarHostState() }
                val coroutineScope = rememberCoroutineScope()
                val state by viewModel.uiState.collectAsStateWithLifecycle()

                Scaffold(
                    topBar = {
                        TopAppBar(
                            title = { Text(text = "Even Glasses Companion") },
                            actions = {
                                IconButton(onClick = { viewModel.refreshBluetoothState() }) {
                                    Icon(Icons.Default.Refresh, contentDescription = "Refresh bluetooth state")
                                }
                                IconButton(onClick = { ensureBlePermission() }) {
                                    Icon(Icons.Default.Bluetooth, contentDescription = "Request permissions")
                                }
                            }
                        )
                    },
                    snackbarHost = { SnackbarHost(snackbarHostState) }
                ) { innerPadding ->
                    MainScreen(
                        state = state,
                        modifier = Modifier.padding(innerPadding),
                        onStartScan = { viewModel.startScan() },
                        onStopScan = { viewModel.stopScan() },
                        onConnect = { device -> viewModel.connect(device.address) },
                        onDisconnect = { viewModel.disconnect() },
                        onEnsureConnected = { viewModel.ensureConnected() },
                        onSendCommand = { hex ->
                            val success = viewModel.sendHexCommand(hex)
                            coroutineScope.launch {
                                snackbarHostState.showSnackbar(
                                    if (success) "Command sent" else "Unable to send packet"
                                )
                            }
                            success
                        },
                        onStartService = { startBleService() },
                        onStopService = { stopBleService() },
                        onReconnectLast = {
                            val success = viewModel.reconnectLast()
                            coroutineScope.launch {
                                snackbarHostState.showSnackbar(
                                    if (success) "Reconnecting to last device" else "No stored device to reconnect"
                                )
                            }
                        }
                    )
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        ensureBlePermission()
        viewModel.refreshBluetoothState()
    }

    private fun ensureBlePermission() {
        if (!BlePermissionUtil.checkBluetoothPermission(this)) {
            Toast.makeText(this, R.string.permission_required, Toast.LENGTH_LONG).show()
        }
    }

    private fun startBleService() {
        val intent = Intent(this, BLEForegroundService::class.java)
        ContextCompat.startForegroundService(this, intent)
    }

    private fun stopBleService() {
        val intent = Intent(this, BLEForegroundService::class.java)
        stopService(intent)
    }
}

@Composable
private fun MainScreen(
    state: BleUiState,
    modifier: Modifier = Modifier,
    onStartScan: () -> Unit,
    onStopScan: () -> Unit,
    onConnect: (BleDeviceSummary) -> Unit,
    onDisconnect: () -> Unit,
    onEnsureConnected: () -> Unit,
    onSendCommand: (String) -> Boolean,
    onStartService: () -> Unit,
    onStopService: () -> Unit,
    onReconnectLast: () -> Unit
) {
    val dateFormatter = remember { SimpleDateFormat("HH:mm:ss", Locale.getDefault()) }
    var commandText by rememberSaveable { mutableStateOf("") }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            ConnectionStatusCard(
                connectionState = state.connectionState,
                scanning = state.scanning,
                onDisconnect = onDisconnect,
                onEnsureConnected = onEnsureConnected,
                onReconnectLast = onReconnectLast
            )
        }

        item {
            ScanControls(
                scanning = state.scanning,
                onStartScan = onStartScan,
                onStopScan = onStopScan
            )
        }

        item {
            DeviceList(devices = state.scanResults, onConnect = onConnect)
        }

        item {
            CommandSection(
                commandText = commandText,
                onCommandChange = {
                    val filtered = it.uppercase(Locale.getDefault()).filter { ch ->
                        ch.isWhitespace() || ch in "0123456789ABCDEF"
                    }
                    commandText = filtered
                },
                onSendCommand = {
                    val sent = onSendCommand(commandText)
                    if (sent) {
                        commandText = ""
                    }
                }
            )
        }

        item {
            ServiceControls(onStartService = onStartService, onStopService = onStopService)
        }

        item {
            NotificationSection(
                bleNotification = state.lastBleNotification,
                notificationEvents = state.recentNotifications,
                dateFormatter = dateFormatter
            )
        }

        item {
            LogSection(logs = state.logs)
        }
    }
}

@Composable
private fun ConnectionStatusCard(
    connectionState: BleConnectionState,
    scanning: Boolean,
    onDisconnect: () -> Unit,
    onEnsureConnected: () -> Unit,
    onReconnectLast: () -> Unit
) {
    ElevatedCard {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            val statusText = when (connectionState) {
                is BleConnectionState.Connected -> "Connected to ${connectionState.address}"
                is BleConnectionState.Connecting -> "Connecting to ${connectionState.address}…"
                is BleConnectionState.Disconnected -> "Disconnected"
                BleConnectionState.Idle -> "Idle"
                is BleConnectionState.Error -> "Error: ${connectionState.message}"
            }
            Text(text = statusText, style = MaterialTheme.typography.titleMedium)
            if (connectionState is BleConnectionState.Connected) {
                Text(
                    text = "Services: ${connectionState.serviceCount} • Writable characteristic: ${if (connectionState.hasWritableCharacteristic) "available" else "missing"}",
                    style = MaterialTheme.typography.bodyMedium
                )
            }
            Text(
                text = if (scanning) "Scanning for devices…" else "Scanner idle",
                style = MaterialTheme.typography.bodySmall
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Button(onClick = onEnsureConnected) {
                    Text("Ensure connection")
                }
                OutlinedButton(onClick = onDisconnect) {
                    Text("Disconnect")
                }
                TextButton(onClick = onReconnectLast) {
                    Text("Reconnect last")
                }
            }
        }
    }
}

@Composable
private fun ScanControls(
    scanning: Boolean,
    onStartScan: () -> Unit,
    onStopScan: () -> Unit
) {
    ElevatedCard {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Button(onClick = onStartScan, enabled = !scanning) {
                Text("Start scan")
            }
            OutlinedButton(onClick = onStopScan, enabled = scanning) {
                Text("Stop scan")
            }
        }
    }
}

@Composable
private fun DeviceList(
    devices: List<BleDeviceSummary>,
    onConnect: (BleDeviceSummary) -> Unit
) {
    ElevatedCard {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(text = "Nearby devices", style = MaterialTheme.typography.titleMedium)
            if (devices.isEmpty()) {
                Text(
                    text = "No devices discovered yet. Tap 'Start scan' to search for your glasses.",
                    style = MaterialTheme.typography.bodySmall
                )
            } else {
                devices.forEach { device ->
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant)
                    ) {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(12.dp),
                            verticalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Text(
                                text = device.displayName,
                                style = MaterialTheme.typography.bodyLarge,
                                fontWeight = FontWeight.SemiBold
                            )
                            Text(
                                text = "Address: ${device.address}",
                                style = MaterialTheme.typography.bodySmall
                            )
                            Text(
                                text = "RSSI: ${device.rssi} dBm",
                                style = MaterialTheme.typography.bodySmall
                            )
                            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Button(onClick = { onConnect(device) }) {
                                    Text("Connect")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CommandSection(
    commandText: String,
    onCommandChange: (String) -> Unit,
    onSendCommand: () -> Unit
) {
    ElevatedCard {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(text = "Send raw hex packet", style = MaterialTheme.typography.titleMedium)
            OutlinedTextField(
                value = commandText,
                onValueChange = onCommandChange,
                modifier = Modifier.fillMaxWidth(),
                label = { Text("Hex bytes (e.g. F5 17)") },
                keyboardOptions = KeyboardOptions.Default.copy(capitalization = KeyboardCapitalization.Characters)
            )
            Button(
                onClick = onSendCommand,
                enabled = commandText.isNotBlank()
            ) {
                Text("Transmit")
            }
        }
    }
}

@Composable
private fun ServiceControls(
    onStartService: () -> Unit,
    onStopService: () -> Unit
) {
    ElevatedCard {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Button(onClick = onStartService) {
                Icon(Icons.Default.PowerSettingsNew, contentDescription = null)
                Spacer(modifier = Modifier.size(8.dp))
                Text("Start foreground service")
            }
            OutlinedButton(onClick = onStopService) {
                Text("Stop service")
            }
        }
    }
}

@Composable
private fun NotificationSection(
    bleNotification: BleNotification?,
    notificationEvents: List<NotificationEvent>,
    dateFormatter: SimpleDateFormat
) {
    ElevatedCard {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Text(text = "Recent data", style = MaterialTheme.typography.titleMedium)
            if (bleNotification != null) {
                Text(
                    text = "Last BLE notification (${bleNotification.characteristicUuid}):",
                    style = MaterialTheme.typography.bodyMedium
                )
                Text(
                    text = bleNotification.hexPayload,
                    style = MaterialTheme.typography.bodySmall,
                    fontWeight = FontWeight.Medium
                )
            } else {
                Text(
                    text = "No BLE notifications received yet.",
                    style = MaterialTheme.typography.bodySmall
                )
            }
            HorizontalDivider()
            Text(text = "Phone notifications", style = MaterialTheme.typography.titleSmall)
            if (notificationEvents.isEmpty()) {
                Text(
                    text = "Grant notification listener access in system settings to mirror alerts.",
                    style = MaterialTheme.typography.bodySmall
                )
            } else {
                notificationEvents.forEach { event ->
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Text(
                            text = "${dateFormatter.format(Date(event.postedAt))} • ${event.packageName}",
                            style = MaterialTheme.typography.bodySmall,
                            fontWeight = FontWeight.Medium
                        )
                        Text(
                            text = event.summary,
                            style = MaterialTheme.typography.bodySmall
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                }
            }
        }
    }
}

@Composable
private fun LogSection(logs: List<String>) {
    ElevatedCard {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Text(text = "Logs", style = MaterialTheme.typography.titleMedium)
            if (logs.isEmpty()) {
                Text(text = "Logs will appear here as Bluetooth events happen.")
            } else {
                logs.takeLast(20).asReversed().forEach { line ->
                    Text(text = line, style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}
