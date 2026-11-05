import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exception.dart';
import '../core/theme.dart';
import '../repositories/puzzle_repository.dart';
import 'error_view.dart';

/// "Save to Word Bank" — only shown for finished puzzles.
class SaveWordButton extends StatefulWidget {
  const SaveWordButton({super.key, required this.puzzleId});

  final int puzzleId;

  @override
  State<SaveWordButton> createState() => _SaveWordButtonState();
}

class _SaveWordButtonState extends State<SaveWordButton> {
  bool _saved = false;
  bool _busy = false;

  Future<void> _toggle() async {
    final repo = context.read<PuzzleRepository>();
    setState(() => _busy = true);
    try {
      if (_saved) {
        await repo.removeWord(widget.puzzleId);
      } else {
        await repo.saveWord(widget.puzzleId);
      }
      if (!mounted) return;
      setState(() => _saved = !_saved);
      showSnack(context, _saved ? 'Saved to your Word Bank.' : 'Removed from your Word Bank.');
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: _busy ? null : _toggle,
      style: OutlinedButton.styleFrom(
        backgroundColor: _saved ? AppColors.goldSoft : Colors.white,
        side: BorderSide(color: _saved ? AppColors.gold : AppColors.navy, width: 2),
      ),
      icon: Icon(_saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
      label: Text(_saved ? 'Saved in Word Bank' : 'Save to Word Bank'),
    );
  }
}
