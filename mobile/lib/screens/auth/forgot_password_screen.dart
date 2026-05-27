import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/auth_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_formatters.dart';
import '../../config/app_validators.dart';
import '../../providers/auth_provider.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  ForgotPasswordResult? _result;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Request a reset token',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the account email. In local development, the reset token will be shown here. In production, the token should be delivered out-of-band.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: AppValidators.email,
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_submitting || auth.busy) ? null : _submit,
                            child: Text(_submitting ? 'Generating...' : 'Request Reset Token'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_result != null)
                Card(
                  color: const Color(0xFFEFF7EC),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Reset Request Status', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(_result!.message),
                        if (_result!.resetToken != null) ...<Widget>[
                          const SizedBox(height: 16),
                          Text('Development Token Preview', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          SelectableText(
                            _result!.resetToken!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text('Expires at: ${formatDateTime(_result!.expiresAt)}'),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ResetPasswordScreen(initialToken: _result!.resetToken),
                                  ),
                                );
                              },
                              child: const Text('Continue To Reset Password'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const ResetPasswordScreen()),
                    );
                  },
                  child: const Text('I already have a reset token'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _submitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      final ForgotPasswordResult result = await AuthApi(auth.apiClient).forgotPassword(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() => _result = result);
      AppFeedback.showSuccess(context, result.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}
