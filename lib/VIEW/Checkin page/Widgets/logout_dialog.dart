import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/VIEW/Login%20page/login_screen.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Logout',
        style: AppStyle.jakartaText(
          context: context,
          size: 18,
          weight: FontWeight.w600,
          color: const Color(0xFF232323),
        ),
      ),
      content: Text(
        'Are you sure you want to logout?',
        style: AppStyle.jakartaText(
          context: context,
          size: 14,
          weight: FontWeight.w400,
          color: const Color(0xFF6B7280),
        ),
      ),
      actions: [
        /// CANCEL
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: AppStyle.jakartaText(
              context: context,
              size: 14,
              weight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ),

        /// LOGOUT
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // close dialog
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) =>  LoginScreen()),
              (route) => false, // clears all previous routes
            );
          },
          child: Text(
            'Logout',
            style: AppStyle.jakartaText(
              context: context,
              size: 14,
              weight: FontWeight.w600,
              color: const Color(0xFFEF4444),
            ),
          ),
        ),
      ],
    );
  }
}
