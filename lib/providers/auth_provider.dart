import 'package:flutter/material.dart';

import '../core/api_exception.dart';
import '../core/api_service.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';

/// Which part of the app the user may see.
enum AuthStatus { unknown, unauthenticated, pending, rejected, verified, admin }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repo, ApiService api, this._navigatorKey) {
    // 401 anywhere → sign out. 403 with a status → move to the right screen.
    api.onUnauthorized = _signOutLocally;
    api.onAccountStatus = _handleAccountStatus;
  }

  final AuthRepository _repo;
  final GlobalKey<NavigatorState> _navigatorKey;

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _startupError;
  bool _busy = false;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get startupError => _startupError;
  bool get busy => _busy;

  /// Runs once on launch: saved token? → load /me.
  Future<void> bootstrap() async {
    if (_startupError != null) {
      _startupError = null; // "Retry" pressed: show the loader again
      notifyListeners();
    }

    if (!await _repo.hasToken()) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }

    try {
      _user = await _repo.me();
      _applyUser();
    } on ApiException catch (e) {
      if (e.isNetwork) {
        _startupError = e.message; // splash screen shows "Retry"
        notifyListeners();
      } else {
        await _repo.clearToken();
        _setStatus(AuthStatus.unauthenticated);
      }
    }
  }

  Future<void> login(String login, String password) => _run(() async {
        _user = await _repo.login(login: login, password: password);
        _applyUser();
      });

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
    required int schoolId,
    required bool privacyAccepted,
  }) =>
      _run(() async {
        _user = await _repo.register(
          username: username,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
          schoolId: schoolId,
          privacyAccepted: privacyAccepted,
        );
        _applyUser();
      });

  /// GET /me again (e.g. "Check status" on the waiting screen).
  Future<void> refreshUser() => _run(() async {
        _user = await _repo.me();
        _applyUser();
      });

  Future<void> uploadSchoolId(String filePath) => _run(() async {
        await _repo.uploadSchoolId(filePath);
        _user = await _repo.me();
        _applyUser();
      });

  Future<void> updateProfile({String? username, String? currentPassword, String? password, String? passwordConfirmation}) =>
      _run(() async {
        _user = await _repo.updateProfile(
          username: username,
          currentPassword: currentPassword,
          password: password,
          passwordConfirmation: passwordConfirmation,
        );
        notifyListeners();
      });

  Future<void> logout() async {
    await _repo.logout();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  // ---------------------------------------------------------------------

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    notifyListeners();
    try {
      await action();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _applyUser() {
    final u = _user;
    if (u == null) {
      _setStatus(AuthStatus.unauthenticated);
    } else if (u.isAdmin) {
      _setStatus(AuthStatus.admin);
    } else if (u.isVerifiedStudent) {
      _setStatus(AuthStatus.verified);
    } else if (u.isRejected) {
      _setStatus(AuthStatus.rejected);
    } else {
      _setStatus(AuthStatus.pending);
    }
  }

  void _setStatus(AuthStatus next) {
    final changed = next != _status;
    _status = next;
    notifyListeners();
    if (changed) {
      // Close pushed screens (games, register...) so the new home shows.
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

  Future<void> _signOutLocally() async {
    if (_status == AuthStatus.unauthenticated) return;
    await _repo.clearToken();
    _user = null;
    _setStatus(AuthStatus.unauthenticated);
  }

  void _handleAccountStatus(String status) {
    if (status == 'inactive') {
      _signOutLocally();
    } else if ((status == 'pending' || status == 'rejected') && _user != null) {
      _user = _user!.copyWith(status: status);
      _applyUser();
    }
  }
}
