import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/SERVICES/battery_saver_service.dart';

class BatterySaverDialog extends StatelessWidget {
  const BatterySaverDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const BatterySaverDialog(),
    );
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
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.of(context).pop();

            await BatterySaverService.instance
                .openBatterySaverSettings();
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }
}