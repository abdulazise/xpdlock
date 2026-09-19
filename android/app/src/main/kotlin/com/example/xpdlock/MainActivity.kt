package com.example.xpdlock

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.bouncycastle.crypto.engines.SerpentEngine
import org.bouncycastle.crypto.engines.TwofishEngine
import org.bouncycastle.crypto.modes.CBCBlockCipher
import org.bouncycastle.crypto.paddings.PaddedBufferedBlockCipher
import org.bouncycastle.crypto.params.KeyParameter
import org.bouncycastle.crypto.params.ParametersWithIV
import org.bouncycastle.jce.provider.BouncyCastleProvider
import java.security.Security

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.xpdlock/crypto"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Add BouncyCastle security provider
        Security.addProvider(BouncyCastleProvider())
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "serpentEncrypt" -> {
                    val data = call.argument<ByteArray>("data")
                    val key = call.argument<ByteArray>("key")
                    val iv = call.argument<ByteArray>("iv")
                    
                    if (data != null && key != null && iv != null) {
                        try {
                            val encrypted = serpentEncrypt(data, key, iv)
                            result.success(encrypted)
                        } catch (e: Exception) {
                            result.error("ENCRYPTION_ERROR", "Failed to encrypt with Serpent", e.toString())
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Invalid arguments for Serpent encryption", null)
                    }
                }
                "serpentDecrypt" -> {
                    val data = call.argument<ByteArray>("data")
                    val key = call.argument<ByteArray>("key")
                    val iv = call.argument<ByteArray>("iv")
                    
                    if (data != null && key != null && iv != null) {
                        try {
                            val decrypted = serpentDecrypt(data, key, iv)
                            result.success(decrypted)
                        } catch (e: Exception) {
                            result.error("DECRYPTION_ERROR", "Failed to decrypt with Serpent", e.toString())
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Invalid arguments for Serpent decryption", null)
                    }
                }
                "twofishEncrypt" -> {
                    val data = call.argument<ByteArray>("data")
                    val key = call.argument<ByteArray>("key")
                    val iv = call.argument<ByteArray>("iv")
                    
                    if (data != null && key != null && iv != null) {
                        try {
                            val encrypted = twofishEncrypt(data, key, iv)
                            result.success(encrypted)
                        } catch (e: Exception) {
                            result.error("ENCRYPTION_ERROR", "Failed to encrypt with Twofish", e.toString())
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Invalid arguments for Twofish encryption", null)
                    }
                }
                "twofishDecrypt" -> {
                    val data = call.argument<ByteArray>("data")
                    val key = call.argument<ByteArray>("key")
                    val iv = call.argument<ByteArray>("iv")
                    
                    if (data != null && key != null && iv != null) {
                        try {
                            val decrypted = twofishDecrypt(data, key, iv)
                            result.success(decrypted)
                        } catch (e: Exception) {
                            result.error("DECRYPTION_ERROR", "Failed to decrypt with Twofish", e.toString())
                        }
                    } else {
                        result.error("INVALID_ARGUMENTS", "Invalid arguments for Twofish decryption", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun serpentEncrypt(data: ByteArray, key: ByteArray, iv: ByteArray): ByteArray {
        val cipher = PaddedBufferedBlockCipher(CBCBlockCipher(SerpentEngine()))
        cipher.init(true, ParametersWithIV(KeyParameter(key), iv))
        
        val outputSize = cipher.getOutputSize(data.size)
        val output = ByteArray(outputSize)
        
        val processLen = cipher.processBytes(data, 0, data.size, output, 0)
        val finalLen = cipher.doFinal(output, processLen)
        
        return output.copyOf(processLen + finalLen)
    }
    
    private fun serpentDecrypt(data: ByteArray, key: ByteArray, iv: ByteArray): ByteArray {
        val cipher = PaddedBufferedBlockCipher(CBCBlockCipher(SerpentEngine()))
        cipher.init(false, ParametersWithIV(KeyParameter(key), iv))
        
        val outputSize = cipher.getOutputSize(data.size)
        val output = ByteArray(outputSize)
        
        val processLen = cipher.processBytes(data, 0, data.size, output, 0)
        val finalLen = cipher.doFinal(output, processLen)
        
        return output.copyOf(processLen + finalLen)
    }
    
    private fun twofishEncrypt(data: ByteArray, key: ByteArray, iv: ByteArray): ByteArray {
        val cipher = PaddedBufferedBlockCipher(CBCBlockCipher(TwofishEngine()))
        cipher.init(true, ParametersWithIV(KeyParameter(key), iv))
        
        val outputSize = cipher.getOutputSize(data.size)
        val output = ByteArray(outputSize)
        
        val processLen = cipher.processBytes(data, 0, data.size, output, 0)
        val finalLen = cipher.doFinal(output, processLen)
        
        return output.copyOf(processLen + finalLen)
    }
    
    private fun twofishDecrypt(data: ByteArray, key: ByteArray, iv: ByteArray): ByteArray {
        val cipher = PaddedBufferedBlockCipher(CBCBlockCipher(TwofishEngine()))
        cipher.init(false, ParametersWithIV(KeyParameter(key), iv))
        
        val outputSize = cipher.getOutputSize(data.size)
        val output = ByteArray(outputSize)
        
        val processLen = cipher.processBytes(data, 0, data.size, output, 0)
        val finalLen = cipher.doFinal(output, processLen)
        
        return output.copyOf(processLen + finalLen)
    }
}