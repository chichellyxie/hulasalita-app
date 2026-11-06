import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';

/// Navy header with rounded bottom corners, drawn behind the status bar.
/// Used instead of an AppBar on the redesigned screens.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.actions = const [],
    this.child,
    this.color = AppColors.navy,
    this.bottomPadding = 22,
    this.emoji,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? child; // extra content under the title row
  final Color color;
  final double bottomPadding;
  final String? emoji; // shown before the title, e.g. the game's emoji

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          // A gradient replaces the flat color for the default navy header.
          color: color == AppColors.navy ? null : color,
          gradient: color == AppColors.navy
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.headerTop, AppColors.headerBottom],
                )
              : null,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, top + 14, 20, bottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                if (showBack) ...[
                  HeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    tooltip: 'Back',
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  ),
                  const SizedBox(width: 12),
                ],
                if (emoji != null) ...[
                  Text(emoji!, style: const TextStyle(fontSize: 28, height: 1)),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: displayStyle(size: 24, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitle != null)
                        Text(subtitle!,
                            style: const TextStyle(color: Color(0xFFC9CDF2), fontSize: 13, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                ...actions,
              ],
            ),
            if (child != null) ...[const SizedBox(height: 16), child!],
          ],
        ),
      ),
    );
  }
}

/// Round translucent icon button for the navy header.
class HeaderButton extends StatelessWidget {
  const HeaderButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.14),
        foregroundColor: Colors.white,
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

/// Small rounded pill (language, difficulty, points…).
class Pill extends StatelessWidget {
  const Pill({super.key, required this.label, this.background = AppColors.navySoft, this.foreground = AppColors.navy, this.icon});

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  factory Pill.difficulty(String difficulty, {int? points}) {
    final (bg, fg) = switch (difficulty) {
      'easy' => (AppColors.correctSoft, const Color(0xFF145C3B)),
      'medium' => (const Color(0xFFFCEBC4), const Color(0xFF6B4600)),
      _ => (AppColors.wrongSoft, AppColors.wrong),
    };
    final name = difficulty.isEmpty ? '' : '${difficulty[0].toUpperCase()}${difficulty.substring(1)}';
    return Pill(label: points == null ? name : '$name · $points pts', background: bg, foreground: fg);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 4)],
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: foreground)),
        ],
      ),
    );
  }
}

/// Uppercase small section label.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: color),
      );
}

/// [AppHeader] that fits in `Scaffold.appBar`, for screens that keep a
/// normal Scaffold layout (admin lists, forms…).
class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const HeaderBar({super.key, required this.title, this.subtitle, this.showBack = true, this.actions = const []});

  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(82);

  @override
  Widget build(BuildContext context) =>
      AppHeader(title: title, subtitle: subtitle, showBack: showBack, actions: actions, bottomPadding: 20);
}
