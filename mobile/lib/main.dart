import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_scroll_behavior.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/common/root_shell.dart';

void main() {
  runApp(const VortexSynergyApp());
}

class VortexSynergyApp extends StatelessWidget {
  const VortexSynergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Vortex Synergy',
        debugShowCheckedModeBanner: false,
        scrollBehavior: const AppScrollBehavior(),
        theme: AppTheme.build(),
        home: const RootShell(),
      ),
    );
  }
}
