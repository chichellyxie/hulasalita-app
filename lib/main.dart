import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_service.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';
import 'providers/auth_provider.dart';
import 'providers/leaderboard_provider.dart';
import 'providers/stats_provider.dart';
import 'repositories/admin_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/puzzle_repository.dart';
import 'repositories/reference_repository.dart';
import 'repositories/stats_repository.dart';
import 'screens/auth_gate.dart';

/// Layers (Figure 2.11): screens/widgets → providers → repositories → ApiService.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokens = TokenStorage();
  final api = ApiService(tokens);

  runApp(HulaSalitaApp(api: api, tokens: tokens));
}

class HulaSalitaApp extends StatelessWidget {
  HulaSalitaApp({super.key, required this.api, required this.tokens});

  final ApiService api;
  final TokenStorage tokens;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository(api, tokens);
    final statsRepo = StatsRepository(api);

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),
        Provider<ReferenceRepository>(create: (_) => ReferenceRepository(api)),
        Provider<PuzzleRepository>(create: (_) => PuzzleRepository(api)),
        Provider<StatsRepository>.value(value: statsRepo),
        Provider<AdminRepository>(create: (_) => AdminRepository(api)),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authRepo, api, _navigatorKey)..bootstrap(),
        ),
        ChangeNotifierProvider<StatsProvider>(create: (_) => StatsProvider(statsRepo)),
        ChangeNotifierProvider<LeaderboardProvider>(create: (_) => LeaderboardProvider(statsRepo)),
      ],
      child: MaterialApp(
        title: 'HulaSalita',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: AppTheme.light(),
        home: const AuthGate(),
      ),
    );
  }
}
