import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'theme.dart';

/// Screen-to-screen animation where screens never overlap.
///
/// Android's default "zoom" transition scales the new screen up from a
/// smaller size and fades it in, so the previous screen shows around its
/// edges and through it while it opens. Here the new screen starts on a
/// solid background that fully covers the old one, and only its content
/// fades in (a "fade through").
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeThrough(animation: animation, child: child);
  }
}

class _FadeThrough extends StatelessWidget {
  const _FadeThrough({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  /// Solid color behind the incoming screen: the dark night color for
  /// student screens, the light background for administrator screens.
  static Color _fillFor(BuildContext context) {
    try {
      final isAdmin = context.read<AuthProvider>().status == AuthStatus.admin;
      return isAdmin ? AppColors.background : AppColors.night;
    } catch (_) {
      return AppColors.night;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fadeIn = CurvedAnimation(parent: animation, curve: const Interval(0.3, 1.0, curve: Curves.easeOut));
    final scaleIn = Tween<double>(begin: 0.97, end: 1.0).animate(fadeIn);
    return ColoredBox(
      color: _fillFor(context),
      child: FadeTransition(
        opacity: fadeIn,
        child: ScaleTransition(scale: scaleIn, child: child),
      ),
    );
  }
}
