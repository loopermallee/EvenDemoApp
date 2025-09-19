package com.example.demo_ai_even.cpp

object Cpp {

    init {
        System.loadLibrary("lc3")
    }

    fun init() = Unit

    @JvmStatic
    external fun decodeLC3(lc3Data: ByteArray?): ByteArray?

    @JvmStatic
    external fun rnNoise(state: Long, input: FloatArray): FloatArray

    @JvmStatic
    external fun createRNNoiseState(): Long

    @JvmStatic
    external fun destroyRNNoiseState(state: Long)
}
