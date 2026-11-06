// Standalone PREVIEW of the new puzzle list (hidden questions + new palette).
// Run it with:  flutter run -t lib/preview_puzzle_list.dart
// It uses sample data, so it does not need the API or login.
import 'package:flutter/material.dart';
import 'theme/app_palette.dart';
import 'widgets/mystery_puzzle_tile.dart';

void main() => runApp(const PreviewApp());

class PreviewApp extends StatelessWidget {
  const PreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HulaSalita preview',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppPalette.bg,
        colorScheme: ColorScheme.fromSeed(
            seedColor: AppPalette.headerB, brightness: Brightness.dark),
      ),
      home: const PuzzleListPreview(),
    );
  }
}

class _Puzzle {
  final int id;
  final String question, language, difficulty, level;
  const _Puzzle(this.id, this.question, this.language, this.difficulty, this.level);
}

const _puzzles = <_Puzzle>[
  _Puzzle(1, 'Isang butil ng palay, sakop ang buong bahay.', 'Filipino', 'Easy', 'Gr 1-3'),
  _Puzzle(2, 'Maliit pa si kumpare, nakakaakyat na sa tore.', 'Filipino', 'Easy', 'Gr 4-6'),
  _Puzzle(3, 'What has hands but cannot clap?', 'English', 'Easy', 'Gr 4-6'),
  _Puzzle(4, 'Bumili ako ng alipin, mataas pa sa akin.', 'Filipino', 'Easy', 'Gr 4-6'),
  _Puzzle(5, 'Isang bayabas, pito ang butas.', 'Filipino', 'Easy', 'Gr 1-3'),
  _Puzzle(6, 'Kung kailan mo pinatay, saka pa humaba ang buhay.', 'Filipino', 'Easy', 'Gr 7-10'),
  _Puzzle(7, 'What has a neck but no head?', 'English', 'Medium', 'Gr 7-10'),
  _Puzzle(8, 'Hindi tao, hindi hayop, may pakpak.', 'Filipino', 'Medium', 'Gr 4-6'),
  _Puzzle(9, 'Ano ang danum sa English?', 'Pangasinan', 'Easy', 'Gr 1-3'),
  _Puzzle(10, 'The more you take, the more you leave behind.', 'English', 'Hard', 'Gr 11-12'),
  _Puzzle(11, 'Nasa loob ang buto, nasa labas ang laman.', 'Filipino', 'Hard', 'Gr 11-12'),
];

class PuzzleListPreview extends StatefulWidget {
  const PuzzleListPreview({super.key});

  @override
  State<PuzzleListPreview> createState() => _PuzzleListPreviewState();
}

class _PuzzleListPreviewState extends State<PuzzleListPreview> {
  String _lang = 'All';
  String _diff = 'Easy';
  final Set<int> _solved = {};

  static const _langs = ['All', 'English', 'Filipino', 'Pangasinan'];
  static const _diffs = ['Easy', 'Medium', 'Hard'];
  static const _pts = {'Easy': 10, 'Medium': 20, 'Hard': 30};

  List<_Puzzle> get _list => _puzzles
      .where((p) =>
          p.difficulty == _diff && (_lang == 'All' || p.language == _lang))
      .toList();

  void _open(_Puzzle p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Puzzle opened',
            style: TextStyle(color: AppPalette.ink, fontWeight: FontWeight.w800)),
        content: Text(p.question,
            style: const TextStyle(color: AppPalette.ink, fontSize: 17)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppPalette.gold,
                foregroundColor: AppPalette.ink),
            onPressed: () {
              setState(() => _solved.add(p.id));
              Navigator.pop(context);
            },
            child: const Text('Mark solved (demo)'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _list;
    final done = list.where((p) => _solved.contains(p.id)).length;
    final unsolved = [
      for (var i = 0; i < list.length; i++)
        if (!_solved.contains(list[i].id)) i
    ];

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppPalette.headerGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Text('🧩', style: TextStyle(fontSize: 30)),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bugtong',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1)),
                          Text('Traditional riddles (NEW DESIGN)',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 14),
                    const Text('CHOOSE A LANGUAGE',
                        style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            fontSize: 12)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final l in _langs)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => setState(() => _lang = l),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _lang == l
                                        ? AppPalette.gold
                                        : Colors.white24,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(l,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: _lang == l
                                              ? AppPalette.ink
                                              : Colors.white)),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Difficulty switch
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  for (final d in _diffs)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _diff = d),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _diff == d
                                ? (d == 'Easy'
                                    ? AppPalette.ok
                                    : d == 'Medium'
                                        ? AppPalette.warn
                                        : AppPalette.bad)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(d,
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: _diff == d
                                      ? Colors.white
                                      : AppPalette.mute)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Progress
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            child: Row(children: [
              Text('★ $done of ${list.length} solved',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: list.isEmpty ? 0 : done / list.length,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    color: AppPalette.gold,
                  ),
                ),
              ),
            ]),
          ),
          // List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                SurpriseButton(
                    unsolvedIndexes: unsolved,
                    onPick: (i) => _open(list[i])),
                if (list.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text('No puzzles here yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppPalette.onDarkMute)),
                  ),
                for (var i = 0; i < list.length; i++)
                  MysteryPuzzleTile(
                    number: i + 1,
                    language: list[i].language,
                    difficulty: list[i].difficulty,
                    level: list[i].level,
                    points: _pts[list[i].difficulty]!,
                    tries: 4,
                    solved: _solved.contains(list[i].id),
                    solvedTitle: list[i].question,
                    onTap: () => _open(list[i]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
