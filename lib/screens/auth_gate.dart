import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'admin/admin_home_screen.dart';
import 'auth/login_screen.dart';
import 'auth/splash_screen.dart';
import 'home/home_screen.dart';
import 'verify/verification_screen.dart';

/// Screen flow (Figure 2.12): no token → login; pending/rejected → waiting
/// screen; approved student → home; admin → admin dashboard.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    return switch (status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.unauthenticated => const LoginScreen(),
      AuthStatus.pending || AuthStatus.rejected => const VerificationScreen(),
      AuthStatus.verified => const HomeScreen(),
      AuthStatus.admin => const AdminHomeScreen(),
    };
  }
}
