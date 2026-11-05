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
              const SizedBox(height: 8),
              const Text('Word games in English, Filipino and Pangasinan',
                  textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFC9CDF2), fontWeight: FontWeight.w600)),
              const SizedBox(height: 32),
              if (auth.startupError == null)
                const CircularProgressIndicator(color: AppColors.gold)
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

/// "HulaSalita" word mark built from letter tiles (gold HULA, white/navy SALITA).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.light = false, this.big = true});

  /// true = on a navy background (white SALITA tiles).
  final bool light;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final hula = big ? 52.0 : 40.0;
    final salita = big ? 44.0 : 34.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: 'HULA'.split('').map((ch) => _tile(ch, hula, AppColors.gold, AppColors.ink, AppColors.goldDark)).toList(),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: 'SALITA'
              .split('')
              .map((ch) => light
                  ? _tile(ch, salita, Colors.white, AppColors.navy, const Color(0xFF9FA6CC))
                  : _tile(ch, salita, AppColors.navy, Colors.white, AppColors.navyDark))
              .toList(),
        ),
        const SizedBox(height: 12),
        Text('Hulaan ang salita!', style: displayStyle(size: big ? 22 : 18, color: light ? AppColors.gold : AppColors.navy, weight: FontWeight.w700)),
      ],
    );
  }

  Widget _tile(String ch, double size, Color background, Color text, Color shadow) => Container(
        width: size,
        height: size + 4,
        margin: const EdgeInsets.symmetric(horizontal: 3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(size * 0.27),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 4))],
        ),
        child: Text(ch, style: displayStyle(size: size * 0.56, color: text)),
      );
}
