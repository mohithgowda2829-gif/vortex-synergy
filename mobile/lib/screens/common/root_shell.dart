import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../admin/admin_dashboard_screen.dart';
import '../auth/login_screen.dart';
import '../auth/splash_screen.dart';
import '../doctor/doctor_verification_screen.dart';
import '../donor/donor_dashboard_screen.dart';
import '../receiver/receiver_dashboard_screen.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (BuildContext context, AuthProvider auth, Widget? child) {
        if (!auth.initialized) {
          return const SplashScreen();
        }
        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        switch (auth.user!.role) {
          case 'DONOR':
            return const DonorDashboardScreen();
          case 'RECEIVER':
            return const ReceiverDashboardScreen();
          case 'DOCTOR_PHARMACIST':
            return const DoctorVerificationScreen();
          case 'ADMIN':
            return const AdminDashboardScreen();
          default:
            return const LoginScreen();
        }
      },
    );
  }
}
