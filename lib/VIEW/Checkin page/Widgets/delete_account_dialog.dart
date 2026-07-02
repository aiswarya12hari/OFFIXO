import 'package:flutter/material.dart';
import 'package:offixo/PROVIDER/Checkin%20Page/delete_account_provider.dart';
import 'package:provider/provider.dart';

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState
    extends State<DeleteAccountDialog> {
  final TextEditingController _controller =
      TextEditingController();

  bool _canDelete = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Delete Account',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'This action is permanent and cannot be undone.',
          ),

          const SizedBox(height: 16),

          const Text(
            'Type DELETE to confirm:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() {
                _canDelete =
                    value.trim() == 'DELETE';
              });
            },
            decoration: const InputDecoration(
              hintText: 'DELETE',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),

        Consumer<DeleteAccountProvider>(
          builder: (context, provider, child) {
            return TextButton(
              onPressed:
                  !_canDelete || provider.isLoading
                  ? null
                  : () async {
                      final success =
                          await provider.deleteAccount();

                      if (!context.mounted) return;

                      Navigator.pop(context);

                      if (success) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );

                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Account deleted successfully',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.errorMessage ??
                                  'Failed to delete account',
                            ),
                          ),
                        );
                      }
                    },
              child: provider.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.red,
                      ),
                    ),
            );
          },
        ),
      ],
    );
  }
}