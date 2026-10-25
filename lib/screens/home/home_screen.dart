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
    const titles = ['Play', 'Leaderboard', 'Profile'];

    return Scaffold(
      appBar: AppBar(title: Text(_index == 0 ? 'HulaSalita' : titles[_index])),
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
          NavigationDestination(icon: Icon(Icons.videogame_asset_outlined), selectedIcon: Icon(Icons.videogame_asset), label: 'Play'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
