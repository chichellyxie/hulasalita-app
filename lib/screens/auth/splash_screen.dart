import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(light: true),
              const SizedBox(height: 32),
              if (auth.startupError == null)
                const CircularProgressIndicator(color: Colors.white)
              else ...[
                Text(auth.startupError!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                  onPressed: () => context.read<AuthProvider>().bootstrap(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// "HulaSalita" word mark built from letter tiles.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : AppColors.navy;
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: 'HULA'.split('').map((ch) => _tile(ch, AppColors.gold)).toList(),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: 'SALITA'.split('').map((ch) => _tile(ch, light ? AppColors.navyLight : AppColors.navy)).toList(),
        ),
        const SizedBox(height: 12),
        Text('Hulaan ang salita!', style: TextStyle(color: color, fontSize: 16, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _tile(String ch, Color background) => Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.all(2),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(6)),
        child: Text(ch, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      );
}
