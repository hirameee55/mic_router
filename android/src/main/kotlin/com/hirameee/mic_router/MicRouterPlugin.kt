package com.hirameee.mic_router

import android.Manifest
import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import androidx.annotation.RequiresApi
import androidx.annotation.RequiresPermission
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

class MicRouterPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var audioManager: AudioManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mic_router")
        channel.setMethodCallHandler(this)

        context = flutterPluginBinding.applicationContext
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getMicInfo" -> {
                result.success(getMicInfo())
            }

            "setMic" -> {
                val id = call.argument<Int>("id")
                if (id == null) {
                    result.error("INVALID_ARGUMENT", "id is required", null)
                    return
                }
                try {
                    setMic(id)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("SET_MIC_FAILED", e.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    private fun getMicInfo(): Map<String, Any?> {
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)

        // マイクとして使えるデバイスのみに絞る
        val micTypes = setOf(
            AudioDeviceInfo.TYPE_BUILTIN_MIC,
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO,   // BluetoothマイクはSCO
            AudioDeviceInfo.TYPE_WIRED_HEADSET,
            AudioDeviceInfo.TYPE_USB_HEADSET,
        )
        val inputs = devices.filter { it.type in micTypes }

        // 現在の録音デバイスを取得（API28以上）
        val currentId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            getPreferredDeviceId()
        } else {
            null
        }

        inputs.forEach {
            println("----")
            println(" type: ${typeDisplayName(it.type)}")
            println(" name: ${it.productName}")
            println(" id: ${it.id}")
        }

        return mapOf(
            "availableInputs" to inputs.map { mapDevice(it) },
            "currentInput" to inputs.firstOrNull { it.id == currentId }?.let { mapDevice(it) }
        )
    }

    @RequiresPermission(Manifest.permission.RECORD_AUDIO)
    @RequiresApi(Build.VERSION_CODES.P)
    private fun getPreferredDeviceId(): Int? {
        // AudioRecord経由で現在の優先デバイスを確認
        val recorder = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            44100,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            AudioRecord.getMinBufferSize(
                44100,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )
        )
        val id = recorder.preferredDevice?.id
        recorder.release()
        return id
    }

    private fun setMic(id: Int) {
        val devices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
        val target = devices.firstOrNull { it.id == id }
            ?: throw Exception("Input not found: $id")

        // BluetoothマイクはSCOの開始が必要
        if (target.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO) {
            audioManager.isBluetoothScoOn = true
            audioManager.startBluetoothSco()
        } else {
            // 他のマイクを選んだ場合はSCOを停止
            audioManager.stopBluetoothSco()
            audioManager.isBluetoothScoOn = false
        }
    }

    private fun mapDevice(device: AudioDeviceInfo): Map<String, Any> {
        return mapOf(
            "id" to device.id,
            "name" to device.productName.toString(),
            "type" to typeDisplayName(device.type)
        )
    }

    private fun typeDisplayName(type: Int): String {
        return when (type) {
            AudioDeviceInfo.TYPE_BUILTIN_MIC     -> "builtInMic"
            AudioDeviceInfo.TYPE_BLUETOOTH_SCO   -> "bluetoothHFP"  // iOSと型名を合わせる
            AudioDeviceInfo.TYPE_WIRED_HEADSET   -> "headsetMic"
            AudioDeviceInfo.TYPE_USB_HEADSET     -> "usbAudio"
            else                                 -> "unknown"
        }
    }
}
