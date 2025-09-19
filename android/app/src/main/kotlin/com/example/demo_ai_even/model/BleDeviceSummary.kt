package com.example.demo_ai_even.model

data class BleDeviceSummary(
    val name: String?,
    val address: String,
    val rssi: Int,
    val lastSeenTimestamp: Long,
    val isBonded: Boolean
) {
    val displayName: String
        get() = name?.takeIf { it.isNotBlank() } ?: address
}
