import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_feedback.dart';
import '../../config/app_validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/glass_panel.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<AuthProvider>().prewarmServer());
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool wide = constraints.maxWidth >= 820;
                    final Widget form = _LoginForm(
                      formKey: _formKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      busy: auth.busy,
                      onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                      onSubmit: _submit,
                      onForgotPassword: _openForgotPassword,
                      onSignup: _openSignup,
                      onDemoSelected: _fillDemo,
                    );

                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const _LoginHero(),
                          const SizedBox(height: 22),
                          form,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const Expanded(child: _LoginHero()),
                        const SizedBox(width: 28),
                        SizedBox(width: 430, child: form),
                      ],
                    );
                  },
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
      await auth.login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    }
  }

  void _fillDemo(_DemoAccount account) {
    setState(() {
      _emailController.text = account.email;
      _passwordController.text = 'Password123!';
    });
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  void _openSignup() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SignupScreen(),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AnimatedEntry(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[colors.primary, colors.tertiary],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 38),
          ),
          const SizedBox(height: 26),
          Text(
            'Vortex Synergy',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.1,
                ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Text(
              'A secure distribution command center for verified food support, medicine compliance, pickup approval, and impact tracking.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 17),
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const <Widget>[
              _FeaturePill(icon: Icons.verified_user_outlined, label: 'Verified roles'),
              _FeaturePill(icon: Icons.medical_services_outlined, label: 'Medicine review'),
              _FeaturePill(icon: Icons.local_shipping_outlined, label: 'Pickup approval'),
              _FeaturePill(icon: Icons.insights_outlined, label: 'Impact dashboard'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.busy,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSignup,
    required this.onDemoSelected,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool busy;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignup;
  final ValueChanged<_DemoAccount> onDemoSelected;

  static const List<_DemoAccount> _demoAccounts = <_DemoAccount>[
    _DemoAccount('Donor', 'donor@vortex.local', Icons.inventory_2_outlined),
    _DemoAccount('Receiver', 'receiver@vortex.local', Icons.diversity_3_outlined),
    _DemoAccount('Doctor', 'doctor@vortex.local', Icons.medical_services_outlined),
    _DemoAccount('Admin', 'admin@vortex.local', Icons.admin_panel_settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedEntry(
      delay: const Duration(milliseconds: 100),
      child: GlassPanel(
        padding: const EdgeInsets.all(22),
        child: AutofillGroup(
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('Access platform', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Use your assigned role account or quick-fill demo access for presentation testing.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.username, AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: AppValidators.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  onFieldSubmitted: (_) {
                    if (!busy) {
                      onSubmit();
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      onPressed: onTogglePassword,
                      icon: Icon(obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: AppValidators.password,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: busy ? null : onSubmit,
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.login_rounded),
                    label: Text(busy ? 'Signing in...' : 'Login'),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onForgotPassword,
                    child: const Text('Forgot password?'),
                  ),
                ),
                const Divider(height: 28),
                Text(
                  'Demo role quick-fill',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _demoAccounts
                      .map(
                        (_DemoAccount account) => ActionChip(
                          avatar: Icon(account.icon, size: 18),
                          label: Text(account.label),
                          onPressed: () => onDemoSelected(account),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                Center(
                  child: TextButton.icon(
                    onPressed: onSignup,
                    icon: const Icon(Icons.person_add_alt_rounded),
                    label: const Text('Create a new account'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 17, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 7),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DemoAccount {
  const _DemoAccount(this.label, this.email, this.icon);

  final String label;
  final String email;
  final IconData icon;
}
