import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      body: IndexedStack(
        index: _index,
        children: const [PlayTab(), LeaderboardTab(), ProfileTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 1) context.read<LeaderboardProvider>().load();
          if (i == 2) context.read<StatsProvider>().load();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sports_esports_outlined), selectedIcon: Icon(Icons.sports_esports), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
