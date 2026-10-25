import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/guess_result.dart';
import '../models/puzzle.dart';
import '../repositories/puzzle_repository.dart';

enum GameState { loading, playing, submitting, finished, failed }

/// State of ONE game screen. Created fresh for every puzzle that is opened.
class GameProvider extends ChangeNotifier {
  GameProvider(this._repo);

  final PuzzleRepository _repo;

  GameState state = GameState.loading;
  Puzzle? puzzle;
  GuessResult? lastResult;
  String? error; // full-screen error (load failed)
  String? message; // small message under the input (e.g. wrong length)
  final List<List<LetterFeedback>> rows = []; // Daily Word Guess board
  final Map<String, String> keyStates = {}; // keyboard colors

  int get triesUsed => lastResult?.triesUsed ?? puzzle?.myAttempt.triesUsed ?? 0;
  int get triesLeft => lastResult?.triesLeft ?? puzzle?.myAttempt.triesLeft ?? 0;
  bool get solved => lastResult?.solved ?? puzzle?.myAttempt.solved ?? false;
  String? get answer => lastResult?.answer ?? puzzle?.answer;

  Future<void> loadDaily() => _load(() => _repo.daily(), daily: true);

  Future<void> loadPuzzle(int id) => _load(() => _repo.show(id));

  Future<void> _load(Future<Puzzle> Function() fetch, {bool daily = false}) async {
    state = GameState.loading;
    error = null;
    notifyListeners();
    try {
      puzzle = await fetch();
      state = puzzle!.myAttempt.finished ? GameState.finished : GameState.playing;
    } on ApiException catch (e) {
      error = (daily && e.statusCode == 404)
          ? 'There is no daily puzzle today yet. Please check again later.'
          : e.message;
      state = GameState.failed;
    }
    notifyListeners();
  }

  /// Returns the result, or null when the guess was not accepted.
  Future<GuessResult?> submit(String guess) async {
    final current = puzzle;
    if (current == null || state != GameState.playing) return null;
    if (guess.trim().isEmpty) {
      message = 'Type your answer first.';
      notifyListeners();
      return null;
    }

    state = GameState.submitting;
    message = null;
    notifyListeners();

    try {
      final result = await _repo.guess(current.id, guess);
      lastResult = result;

      final letters = result.letters;
      if (letters != null) {
        rows.add(letters);
        for (final l in letters) {
          keyStates[l.letter] = _better(keyStates[l.letter], l.state);
        }
      }

      if (result.finished) {
        state = GameState.finished;
      } else {
        state = GameState.playing;
        message = 'Not quite! ${result.triesLeft} ${result.triesLeft == 1 ? 'try' : 'tries'} left.';
      }
      notifyListeners();
      return result;
    } on ApiException catch (e) {
      state = e.statusCode == 422 && e.message.contains('already finished') ? GameState.finished : GameState.playing;
      message = e.fieldError('guess') ?? e.message;
      notifyListeners();
      return null;
    }
  }

  /// correct beats present beats absent.
  String _better(String? oldState, String newState) {
    const rank = {'absent': 0, 'present': 1, 'correct': 2};
    if (oldState == null) return newState;
    return (rank[newState] ?? 0) > (rank[oldState] ?? 0) ? newState : oldState;
  }
}
