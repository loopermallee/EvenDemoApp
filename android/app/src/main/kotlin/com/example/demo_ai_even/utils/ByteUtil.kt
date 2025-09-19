package com.example.demo_ai_even.utils

object ByteUtil {

    fun byteToHexArray(bytes: ByteArray?): String {
        if (bytes == null) {
            return ""
        }
        val sb = StringBuilder()
        for (b in bytes) {
            sb.append(byteToHex(b))
        }
        return sb.toString().trim()
    }

    private fun byteToHex(b: Byte): String = String.format("%02X ", b)

    fun hexToByteArray(input: String): ByteArray? {
        val sanitized = input.replace(" ", "")
            .replace("\n", "")
            .replace("\t", "")
            .replace("\r", "")
        if (sanitized.isEmpty()) return ByteArray(0)
        if (sanitized.length % 2 != 0) {
            return null
        }
        val bytes = ByteArray(sanitized.length / 2)
        var index = 0
        while (index < sanitized.length) {
            val hex = sanitized.substring(index, index + 2)
            val value = hex.toIntOrNull(16) ?: return null
            bytes[index / 2] = value.toByte()
            index += 2
        }
        return bytes
    }
}
