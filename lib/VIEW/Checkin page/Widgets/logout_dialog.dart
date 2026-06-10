import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Checkin%20Page/logout_provider.dart';
import 'package:offixo/VIEW/Login%20page/login_screen.dart';
import 'package:provider/provider.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LogoutProvider(),
      child: const _LogoutDialogContent(),
    );
  }
}

class _LogoutDialogContent extends StatelessWidget {
  const _LogoutDialogContent();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LogoutProvider>();

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
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Are you sure you want to logout?',
            style: AppStyle.jakartaText(
              context: context,
              size: 14,
              weight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              provider.errorMessage!,
              style: AppStyle.jakartaText(
                context: context,
                size: 12,
                weight: FontWeight.w400,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ],
      ),
      actions: [
        /// CANCEL
        TextButton(
          onPressed: provider.isLoading ? null : () => Navigator.of(context).pop(),
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
          onPressed: provider.isLoading
              ? null
              : () async {
                  final success = await provider.logout();
                  if (success && context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
          child: provider.isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFEF4444),
                  ),
                )
              : Text(
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