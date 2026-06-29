import 'package:flutter/services.dart';

class BackgroundTask {
  static const _channel = MethodChannel('com.vanhci.facematch/background');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod('startTask');
    } catch (_) {}
  }

  static Future<void> end() async {
    try {
      await _channel.invokeMethod('endTask');
    } catch (_) {}
  }
}
