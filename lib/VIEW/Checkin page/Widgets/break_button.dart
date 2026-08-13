import 'package:flutter/material.dart';
import 'package:offixo/CORE/Widget/app_style.dart';
import 'package:offixo/PROVIDER/Checkin%20Page/break_provider.dart';
import 'package:provider/provider.dart';

class BreakButton extends StatelessWidget {
  const BreakButton({super.key});

  void _showBreakDialog(BuildContext context) {
    final reasons = ['Tea Break', 'Lunch Break', 'Prayer Break', 'Other'];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Break Reason',
                style: AppStyle.jakartaText(
                  context: context,
                  size: 16,
                  weight: FontWeight.w700,
                  color: AppStyle.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              ...reasons.map(
                (reason) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.coffee_outlined),
                  title: Text(
                    reason,
                    style: AppStyle.jakartaText(
                      context: context,
                      size: 14,
                      weight: FontWeight.w500,
                      color: AppStyle.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _submitBreak(context, reason);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitBreak(BuildContext context, String reason) async {
    final provider = context.read<BreakProvider>();

    await provider.startBreak(reason: reason);

    if (!context.mounted) return;

    _showSnackbar(context, provider);
  }

  Future<void> _submitEndBreak(BuildContext context) async {
    final provider = context.read<BreakProvider>();

    await provider.endBreak();

    if (!context.mounted) return;

    _showSnackbar(context, provider);
  }

  void _showSnackbar(BuildContext context, BreakProvider provider) {
    final isSuccess = provider.status == BreakStatus.success;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSuccess ? provider.successMessage : provider.errorMessage,
        ),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BreakProvider>(
      builder: (context, provider, child) {
        debugPrint(
          'BUTTON BUILD => isOnBreak=${provider.isOnBreak}, status=${provider.status}',
        );

        final isOnBreak = provider.isOnBreak;

        return GestureDetector(
          onTap: provider.isLoading
              ? null
              : () {
                  if (isOnBreak) {
                    _submitEndBreak(context);
                  } else {
                    _showBreakDialog(context);
                  }
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: isOnBreak
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isOnBreak
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF9800),
                width: 1.5,
              ),
            ),
            child: provider.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isOnBreak
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFF9800),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOnBreak
                            ? Icons.play_circle_outline
                            : Icons.coffee_outlined,
                        color: isOnBreak
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOnBreak ? 'Resume Work' : 'Take a Break',
                        style: AppStyle.jakartaText(
                          context: context,
                          size: 14,
                          weight: FontWeight.w600,
                          color: isOnBreak
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFFF9800),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
