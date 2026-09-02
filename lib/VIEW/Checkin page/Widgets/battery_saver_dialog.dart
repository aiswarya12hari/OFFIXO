import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';

enum BatterySaverDialogResult { cancelled, openedSettings }

class BatterySaverDialog extends StatelessWidget {
  const BatterySaverDialog({super.key});

  static Future<BatterySaverDialogResult> show(BuildContext context) async {
    final result = await showDialog<BatterySaverDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BatterySaverDialog(),
    );

    return result ?? BatterySaverDialogResult.cancelled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Battery Saver is On',
        style: AppStyle.jakartaText(
          context: context,
          size: 17,
          weight: FontWeight.w700,
        ),
      ),
      content: Text(
        'Battery Saver can affect location accuracy and may cause '
        'check-in/check-out to fail. Please turn off Battery Saver '
        'and return to Offixo.',
        style: AppStyle.jakartaText(
          context: context,
          size: 14,
          weight: FontWeight.w400,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(BatterySaverDialogResult.cancelled);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(BatterySaverDialogResult.openedSettings);
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}