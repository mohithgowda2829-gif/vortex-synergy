import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_feedback.dart';
import '../providers/auth_provider.dart';

class VerificationBanner extends StatelessWidget {
  const VerificationBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final ColorScheme colors = Theme.of(context).colorScheme;

    if (auth.user == null || auth.user!.accountVerified) {
      return const SizedBox.shrink();
    }

    return Card(
      color: const Color(0xFFFFF7E7),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Complete verification', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                ElevatedButton.icon(
                  onPressed: auth.busy
                      ? null
                      : () => _verify(context, auth, 'EMAIL'),
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: const Text('Verify Email'),
                ),
                ElevatedButton.icon(
                  onPressed: auth.busy
                      ? null
                      : () => _verify(context, auth, 'PHONE'),
                  icon: const Icon(Icons.phone_iphone_rounded),
                  label: const Text('Verify Phone'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'This MVP uses a placeholder verification flow. Enter any demo code with at least 4 characters to mark the selected channel as verified.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verify(BuildContext context, AuthProvider auth, String channel) async {
    final TextEditingController codeController = TextEditingController();
    final String? code = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verify $channel'),
          content: TextField(
            controller: codeController,
            decoration: const InputDecoration(labelText: 'Verification code'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(codeController.text.trim()),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );

    codeController.dispose();
    if (code == null || code.isEmpty) {
      return;
    }

    try {
      await auth.verifyPlaceholder(channel, code);
      if (context.mounted) {
        AppFeedback.showSuccess(context, '$channel verified successfully');
      }
    } catch (error) {
      if (context.mounted) {
        AppFeedback.showError(context, error);
      }
    }
  }
}
