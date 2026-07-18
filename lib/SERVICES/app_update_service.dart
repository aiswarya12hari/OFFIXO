// import 'package:flutter/material.dart';
// import 'package:in_app_update/in_app_update.dart';

// class AppUpdateService {
//   static Future<void> checkForUpdate() async {
//     try {
//       final updateInfo = await InAppUpdate.checkForUpdate();

//       debugPrint("Update Available: ${updateInfo.updateAvailability}");

//       if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
//         await InAppUpdate.performImmediateUpdate();
//       }
//     } catch (e) {
//       debugPrint("Update Error: $e");
//     }
//   }
// }

import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  /// Call on every app start.
  /// - If an update is downloading/available, silently starts the download.
  /// - If a previous flexible update has already finished downloading,
  ///   silently completes install before the user sees anything.
  static Future<void> checkForUpdate() async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      debugPrint("Update status: ${updateInfo.updateAvailability}");
      debugPrint("Install status: ${updateInfo.installStatus}");

      // Case 1: A flexible update was already downloaded on a previous
      // app open — silently install it now, before showing any screen.
      if (updateInfo.installStatus == InstallStatus.downloaded) {
        await InAppUpdate.completeFlexibleUpdate();
        debugPrint("Silently completed pending update");
        return;
      }

      // Case 2: New update available — start downloading silently.
      if (updateInfo.updateAvailability ==
          UpdateAvailability.updateAvailable) {
        if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          debugPrint("Started silent background download");
          // No snackbar, no prompt — installs automatically on a future app open.
        } else if (updateInfo.immediateUpdateAllowed) {
          // Fallback only if Play Store forces this update to be immediate
          // (e.g. very old version, or you marked it as high-priority in Play Console).
          await InAppUpdate.performImmediateUpdate();
        }
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }
}
