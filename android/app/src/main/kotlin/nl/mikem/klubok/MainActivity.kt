package nl.mikem.klubok

import android.view.KeyEvent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Две вещи, которые удобнее сделать на стороне Android:
 *  - не давать экрану гаснуть, пока открыт счётчик;
 *  - отдавать кнопки громкости счётчику рядов.
 * Вторая половина живёт в lib/device.dart.
 */
class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var captureVolumeKeys = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val ch = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "klubok/device")
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                "setKeepScreenOn" -> {
                    if (call.arguments == true) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(null)
                }
                "setVolumeKeyCapture" -> {
                    captureVolumeKeys = call.arguments == true
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        channel = ch
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val code = event.keyCode
        val isVolume = code == KeyEvent.KEYCODE_VOLUME_UP || code == KeyEvent.KEYCODE_VOLUME_DOWN
        if (captureVolumeKeys && isVolume) {
            // Считаем одно нажатие, а не удержание; отпускание тоже забираем,
            // чтобы система не показывала ползунок громкости.
            if (event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                val direction = if (code == KeyEvent.KEYCODE_VOLUME_UP) "up" else "down"
                channel?.invokeMethod("volumeKey", direction)
            }
            return true
        }
        return super.dispatchKeyEvent(event)
    }
}
