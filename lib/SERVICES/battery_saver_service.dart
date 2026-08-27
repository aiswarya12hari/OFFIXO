import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';

class BatterySaverService {
  BatterySaverService._();

  static final BatterySaverService instance = BatterySaverService._();

  final Battery _battery = Battery();

  /// Returns true when Android Battery Saver / Low Power Mode is ON.
  Future<bool> isBatterySaverOn() async {
    try {
      final isOn = await _battery.isInBatterySaveMode;

      debugPrint(
        '[BATTERY SAVER] Current status: ${isOn ? "ON" : "OFF"}',
      );

      return isOn;
    } catch (e) {
      debugPrint(
        '[BATTERY SAVER] Failed to read battery saver status: $e',
      );

      // Do not block the attendance flow if the device/plugin
      // cannot provide the battery saver status.
      return false;
    }
  }

  /// Opens Android Battery Saver settings.
  Future<void> openBatterySaverSettings() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      const intent = AndroidIntent(
        action: 'android.settings.BATTERY_SAVER_SETTINGS',
      );

      await intent.launch();

      debugPrint('[BATTERY SAVER] Settings opened');
    } catch (e) {
      debugPrint(
        '[BATTERY SAVER] Battery Saver settings failed: $e',
      );

      try {
        const fallbackIntent = AndroidIntent(
          action: 'android.settings.SETTINGS',
        );

        await fallbackIntent.launch();

        debugPrint('[BATTERY SAVER] General settings opened');
      } catch (e2) {
        debugPrint(
          '[BATTERY SAVER] General settings failed: $e2',
        );
      }
    }
  }
}