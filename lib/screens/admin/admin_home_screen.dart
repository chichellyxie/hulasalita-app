import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/error_view.dart';
import 'admin_puzzles_screen.dart';
import 'manage_screen.dart';
import 'reports_screen.dart';
import 'verification_queue_screen.dart';

/// Admin dashboard: Verification queue · Puzzles · Manage · Reports.
class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  static const _titles = ['Verification queue', 'Puzzles', 'Manage', 'Reports'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin · ${_titles[_index]}'),
        actions: [
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final ok = await confirmDialog(context, title: 'Log out?', message: 'End the admin session on this device?', confirmLabel: 'Log out');
              if (ok && context.mounted) await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [VerificationQueueScreen(), AdminPuzzlesScreen(), ManageScreen(), ReportsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.verified_user_outlined), selectedIcon: Icon(Icons.verified_user), label: 'Queue'),
          NavigationDestination(icon: Icon(Icons.extension_outlined), selectedIcon: Icon(Icons.extension), label: 'Puzzles'),
          NavigationDestination(icon: Icon(Icons.tune), label: 'Manage'),
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Reports'),
        ],
      ),
    );
  }
}
