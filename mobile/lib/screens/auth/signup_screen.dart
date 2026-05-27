import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_feedback.dart';
import '../../config/app_validators.dart';
import '../../providers/auth_provider.dart';
import 'role_selection_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _selectedRole = 'DONOR';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (String? value) => AppValidators.required(value, label: 'Full name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: AppValidators.email,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      validator: AppValidators.phone,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: AppValidators.password,
                    ),
                    const SizedBox(height: 18),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Role'),
                      subtitle: Text(_selectedRole.replaceAll('_', ' ')),
                      trailing: const Icon(Icons.keyboard_arrow_down_rounded),
                      onTap: () async {
                        final String? role = await Navigator.of(context).push<String>(
                          MaterialPageRoute<String>(
                            builder: (_) => const RoleSelectionScreen(),
                          ),
                        );
                        if (role != null) {
                          setState(() => _selectedRole = role);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: auth.busy ? null : _submit,
                        child: Text(auth.busy ? 'Creating account...' : 'Create account'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Doctor and pharmacist accounts remain pending until an admin approves them.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final AuthProvider auth = context.read<AuthProvider>();
    try {
      await auth.register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Account created. Complete verification in your dashboard.');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }
}
