import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  static Future<void> checkForUpdate() async {
    try {
      final updateInfo =
          await InAppUpdate.checkForUpdate();

      debugPrint(
        "Update Available: ${updateInfo.updateAvailability}",
      );

      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint(
        "Update Error: $e",
      );
    }
  }
}