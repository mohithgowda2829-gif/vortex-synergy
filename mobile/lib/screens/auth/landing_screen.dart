import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/animated_entry.dart';
import '../../widgets/animated_gradient_background.dart';
import '../../widgets/glass_panel.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<AuthProvider>().prewarmServer());
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return AnimatedGradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final bool wide = constraints.maxWidth >= 860;
                    final Widget hero = AnimatedEntry(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[colors.primary, colors.tertiary],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: colors.primary.withValues(alpha: 0.24),
                                  blurRadius: 30,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 44),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Vortex Synergy',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.4,
                                ),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: Text(
                              'A secure and fair resource distribution platform that connects donors, receivers, doctors, and admins to manage food and medicine support safely.',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(height: 1.45),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const <Widget>[
                              _LandingChip(icon: Icons.inventory_2_outlined, label: 'Food donations'),
                              _LandingChip(icon: Icons.medical_services_outlined, label: 'Medicine verification'),
                              _LandingChip(icon: Icons.verified_user_outlined, label: 'Trusted pickup'),
                              _LandingChip(icon: Icons.insights_outlined, label: 'Impact analytics'),
                            ],
                          ),
                        ],
                      ),
                    );

                    final Widget actions = AnimatedEntry(
                      delay: const Duration(milliseconds: 120),
                      child: GlassPanel(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text('Get started', style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 10),
                            Text(
                              'Choose how you want to enter the platform. Existing users can sign in, and new users can create an account with the correct role.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                                );
                              },
                              icon: const Icon(Icons.login_rounded),
                              label: const Text('Proceed to Login'),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const SignupScreen()),
                                );
                              },
                              icon: const Icon(Icons.person_add_alt_rounded),
                              label: const Text('Create an Account'),
                            ),
                            const SizedBox(height: 22),
                            const Divider(),
                            const SizedBox(height: 14),
                            Text(
                              'Primary roles in the app',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 14),
                            const _RoleTile(
                              title: 'Donor',
                              subtitle: 'Creates food and medicine listings and verifies handover at pickup.',
                              icon: Icons.favorite_border_outlined,
                            ),
                            const SizedBox(height: 10),
                            const _RoleTile(
                              title: 'Receiver',
                              subtitle: 'Browses resources, raises claims, and assigns pickup or delivery agents.',
                              icon: Icons.diversity_3_outlined,
                            ),
                            const SizedBox(height: 10),
                            const _RoleTile(
                              title: 'Doctor / Pharmacist',
                              subtitle: 'Approves or rejects medicine donations using compliance checks and notes.',
                              icon: Icons.local_hospital_outlined,
                            ),
                            const SizedBox(height: 10),
                            const _RoleTile(
                              title: 'Admin',
                              subtitle: 'Monitors users, resources, approvals, reports, and overall platform activity.',
                              icon: Icons.admin_panel_settings_outlined,
                            ),
                          ],
                        ),
                      ),
                    );

                    if (!wide) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          hero,
                          const SizedBox(height: 24),
                          actions,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: hero),
                        const SizedBox(width: 28),
                        SizedBox(width: 420, child: actions),
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
}

class _LandingChip extends StatelessWidget {
  const _LandingChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
