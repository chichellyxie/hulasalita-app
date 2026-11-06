import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Shared building blocks for the dark ("night") student screens, so the
/// games, result sheet and profile all look like the Home screen.
class Night {
  // Surfaces
  static const Color bg = AppColors.night; // screen background
  static const Color card = AppColors.nightCard; // raised card
  static const Color cardDeep = Color(0xFF1C1F58); // inner cells inside a card
  static const Color line = AppColors.nightLine;
  static const Color text = AppColors.onNight;
  static const Color textMuted = AppColors.onNightMuted;
  static const Color label = AppColors.lavender;

  // Answer feedback: pastel tones from the Home tiles, with dark text,
  // so right and wrong are clear without harsh red/green.
  static const Color correct = Color(0xFF9BE5C2); // mint tile
  static const Color correctDeep = Color(0xFF2E9E74); // icon / border
  static const Color wrong = Color(0xFFFFB3C8); // rose tile
  static const Color wrongDeep = Color(0xFFD0587C); // icon / border
  static const Color selected = AppColors.gold;

  // Difficulty: emoji, label, points, pastel color
  static const difficulties = <(String, String, String, int, Color)>[
    ('easy', 'Easy', '🙂', 10, Color(0xFF9BE5C2)),
    ('medium', 'Medium', '😎', 20, Color(0xFFFFE08A)),
    ('hard', 'Hard', '🔥', 30, Color(0xFFFFA8C5)),
  ];

  static (String, String, int, Color) difficulty(String code) {
    for (final d in difficulties) {
      if (d.$1 == code) return (d.$2, d.$3, d.$4, d.$5);
    }
    return ('Easy', '🙂', 10, const Color(0xFF9BE5C2));
  }
}

/// Dark card with a soft border (replaces white cards on night screens).
class NightCard extends StatelessWidget {
  const NightCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color = Night.card, this.radius = 22});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Night.line),
        ),
        child: child,
      );
}

/// Small uppercase label in lavender (section titles on night screens).
class NightLabel extends StatelessWidget {
  const NightLabel(this.text, {super.key, this.color = Night.label});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.2, color: color),
      );
}

/// Big gold "3D" button used for the main action on night screens.
class GoldButton extends StatelessWidget {
  const GoldButton({super.key, required this.label, required this.onPressed, this.icon, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.5,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 4))],
        ),
        child: Material(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: 56,
              child: Center(
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ink))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[Icon(icon, color: AppColors.ink), const SizedBox(width: 8)],
                          Text(label, style: displayStyle(size: 19, color: AppColors.ink)),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Outlined button in lavender for secondary actions on night screens.
class NightOutlinedButton extends StatelessWidget {
  const NightOutlinedButton({super.key, required this.label, required this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Night.card,
          side: const BorderSide(color: Night.label, width: 1.5),
          minimumSize: const Size.fromHeight(52),
        ),
        icon: Icon(icon ?? Icons.arrow_forward_rounded),
        label: Text(label),
      );
}

/// Text field styled for night screens.
InputDecoration nightInput(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Night.textMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
      prefixIcon: icon == null ? null : Icon(icon, color: Night.textMuted),
      filled: true,
      fillColor: Night.card,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Night.line, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.gold, width: 2)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Night.line, width: 2)),
    );

/// Rounded pill for night screens (difficulty, points, level...).
class NightPill extends StatelessWidget {
  const NightPill(this.label, {super.key, this.color = Night.cardDeep, this.textColor = Night.text, this.emoji});

  final String label;
  final Color color;
  final Color textColor;
  final String? emoji;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
        child: Text(emoji == null ? label : '$emoji $label', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
      );
}

/// Wrap a form in this to give every field, checkbox, dropdown and
/// segmented button the night look (used by Login, Create account,
/// Verification, Edit profile).
class NightFormTheme extends StatelessWidget {
  const NightFormTheme({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    OutlineInputBorder border(Color c) => OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: 2));
    final inputs = base.inputDecorationTheme.copyWith(
      filled: true,
      fillColor: Night.card,
      labelStyle: const TextStyle(color: Night.textMuted),
      floatingLabelStyle: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800),
      hintStyle: const TextStyle(color: Night.textMuted),
      helperStyle: const TextStyle(color: Night.textMuted),
      errorStyle: const TextStyle(color: Night.wrong, fontWeight: FontWeight.w700),
      prefixIconColor: Night.textMuted,
      suffixIconColor: Night.textMuted,
      border: border(Night.line),
      enabledBorder: border(Night.line),
      focusedBorder: border(AppColors.gold),
      errorBorder: border(Night.wrongDeep),
      focusedErrorBorder: border(Night.wrong),
    );
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
        inputDecorationTheme: inputs,
        textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.gold, selectionColor: Color(0x55F2B233), selectionHandleColor: AppColors.gold),
        listTileTheme: const ListTileThemeData(textColor: Colors.white, iconColor: Night.textMuted),
        textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: AppColors.gold, textStyle: const TextStyle(fontWeight: FontWeight.w800))),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.gold : Colors.transparent),
          checkColor: const WidgetStatePropertyAll(AppColors.ink),
          side: const BorderSide(color: Night.label, width: 2),
        ),
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            backgroundColor: Night.card,
            foregroundColor: Night.text,
            selectedBackgroundColor: AppColors.gold,
            selectedForegroundColor: AppColors.ink,
            side: const BorderSide(color: Night.line, width: 1.5),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: inputs,
          textStyle: const TextStyle(color: Colors.white, fontSize: 16),
          menuStyle: const MenuStyle(backgroundColor: WidgetStatePropertyAll(Night.card)),
        ),
        menuButtonTheme: MenuButtonThemeData(style: MenuItemButton.styleFrom(foregroundColor: Colors.white)),
        progressIndicatorTheme: const ProgressIndicatorThemeData(color: AppColors.gold, linearTrackColor: Night.line),
      ),
      child: child,
    );
  }
}
