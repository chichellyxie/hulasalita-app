import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/leaderboard_provider.dart';
import '../../providers/stats_provider.dart';
import '../leaderboard/leaderboard_tab.dart';
import '../profile/profile_tab.dart';
import 'play_tab.dart';

/// Verified student home: Play · Leaderboard · Profile.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StatsProvider>().load();
      context.read<LeaderboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Each tab draws its own navy AppHeader (no AppBar here).
    return Scaffold(
      backgroundColor: AppColors.night,
      body: IndexedStack(
        index: _index,
        children: const [PlayTab(), LeaderboardTab(), ProfileTab()],
      ),
      bottomNavigationBar: _NightNavBar(
        index: _index,
        onSelect: (i) {
          setState(() => _index = i);
          if (i == 1) context.read<LeaderboardProvider>().load();
          if (i == 2) context.read<StatsProvider>().load();
        },
      ),
    );
  }
}

/// Dark bottom navigation with emoji icons and a gold pill for the open tab.
class _NightNavBar extends StatelessWidget {
  const _NightNavBar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  static const _items = [('🎮', 'Play'), ('🏆', 'Leaderboard'), ('🦉', 'Profile')];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.nightCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == index,
                    button: true,
                    label: _items[i].$2,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: i == index ? AppColors.gold : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: i == index ? 1.15 : 1,
                              duration: const Duration(milliseconds: 220),
                              child: Text(_items[i].$1, style: const TextStyle(fontSize: 22, height: 1.1)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _items[i].$2,
                              style: displayStyle(
                                size: 13,
                                weight: FontWeight.w800,
                                color: i == index ? AppColors.ink : AppColors.lavender,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
