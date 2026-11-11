import 'dart:async';

import 'package:flutter/services.dart';

/// Мостик к Android: экран не гаснет, кнопки громкости считают ряды.
/// Вся «родная» часть — в MainActivity.kt.
class Device {
  static const _channel = MethodChannel('klubok/device');

  static final StreamController<bool> _volume =
      StreamController<bool>.broadcast();

  /// true — нажата «громкость вверх», false — «вниз».
  static Stream<bool> get volumeKeys => _volume.stream;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'volumeKey') {
        _volume.add(call.arguments == 'up');
      }
      return null;
    });
  }

  static Future<void> keepScreenOn(bool on) => _call('setKeepScreenOn', on);

  static Future<void> captureVolumeKeys(bool on) =>
      _call('setVolumeKeyCapture', on);

  static Future<void> _call(String method, bool value) async {
    try {
      await _channel.invokeMethod<void>(method, value);
    } on MissingPluginException {
      // Не Android — просто ничего не делаем.
    } on PlatformException {
      // Не получилось — счётчик работает и без этого.
    }
  }
}
