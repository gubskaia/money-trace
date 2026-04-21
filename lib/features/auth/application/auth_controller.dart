import 'package:flutter/foundation.dart';
import 'package:money_trace/features/auth/domain/models/auth_session.dart';
import 'package:money_trace/features/auth/domain/repositories/auth_repository.dart';

enum AuthStage {
  signIn,
  signUp,
  onboardingCurrency,
  onboardingAccount,
  onboardingComplete,
  authenticated,
}

class AuthController extends ChangeNotifier {
  AuthController({required this.repository});

  final AuthRepository repository;

  AuthStage _stage = AuthStage.signIn;
  AuthSession? _session;
  String _displayName = 'Alex Kowalski';
  String _email = 'alex@moneytrace.app';
  String _preferredCurrencyCode = 'KZT';
  String _starterAccountName = 'Main Wallet';
  double _starterBalance = 0;
  String? _pendingPassword;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthStage get stage => _stage;
  String? get currentUserId => _session?.userId;
  String get displayName => _displayName;
  String get email => _email;
  String get preferredCurrencyCode => _preferredCurrencyCode;
  String get starterAccountName => _starterAccountName;
  double get starterBalance => _starterBalance;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _session != null && _stage == AuthStage.authenticated;

  String get initials {
    final parts = _displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'MT';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> restoreSession() async {
    _errorMessage = null;
    final session = await repository.restoreSession();
    if (session == null) {
      _session = null;
      _stage = AuthStage.signIn;
      notifyListeners();
      return;
    }

    _applySession(session);
    _stage = AuthStage.authenticated;
    notifyListeners();
  }

  void showSignIn() {
    _errorMessage = null;
    _pendingPassword = null;
    _stage = AuthStage.signIn;
    notifyListeners();
  }

  void showSignUp() {
    _errorMessage = null;
    _pendingPassword = null;
    _stage = AuthStage.signUp;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) async {
    final trimmedEmail = email.trim();
    if (!_isValidEmail(trimmedEmail)) {
      _setError('Enter a valid email address.');
      return false;
    }
    if (password.trim().length < 4) {
      _setError('Password should contain at least 4 characters.');
      return false;
    }

    return _submit(() async {
      final session = await repository.signIn(
        email: trimmedEmail,
        password: password,
      );
      _applySession(session);
      _stage = AuthStage.authenticated;
      _pendingPassword = null;
    });
  }

  Future<bool> startRegistration({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();

    if (trimmedName.length < 2) {
      _setError('Enter your full name.');
      return false;
    }
    if (!_isValidEmail(trimmedEmail)) {
      _setError('Enter a valid email address.');
      return false;
    }
    if (password.trim().length < 4) {
      _setError('Password should contain at least 4 characters.');
      return false;
    }

    return _submit(() async {
      final exists = await repository.emailExists(trimmedEmail);
      if (exists) {
        throw StateError('An account with this email already exists.');
      }

      _displayName = trimmedName;
      _email = trimmedEmail.toLowerCase();
      _preferredCurrencyCode = 'KZT';
      _starterAccountName = '${trimmedName.split(' ').first} Wallet';
      _starterBalance = 0;
      _pendingPassword = password;
      _stage = AuthStage.onboardingCurrency;
    });
  }

  void selectCurrency(String currencyCode) {
    _errorMessage = null;
    _preferredCurrencyCode = currencyCode.trim().toUpperCase();
    notifyListeners();
  }

  void goToAccountSetup() {
    _errorMessage = null;
    _stage = AuthStage.onboardingAccount;
    notifyListeners();
  }

  Future<bool> saveStarterAccount({
    required String accountName,
    required double openingBalance,
  }) async {
    final trimmedName = accountName.trim();
    if (trimmedName.length < 2) {
      _setError('Enter a name for your first account.');
      return false;
    }
    if (openingBalance < 0) {
      _setError('Initial balance cannot be negative.');
      return false;
    }

    return _submit(() async {
      _starterAccountName = trimmedName;
      _starterBalance = openingBalance;
      _stage = AuthStage.onboardingComplete;
    });
  }

  void goBack() {
    _errorMessage = null;
    switch (_stage) {
      case AuthStage.signIn:
        return;
      case AuthStage.signUp:
        _stage = AuthStage.signIn;
      case AuthStage.onboardingCurrency:
        _stage = AuthStage.signUp;
      case AuthStage.onboardingAccount:
        _stage = AuthStage.onboardingCurrency;
      case AuthStage.onboardingComplete:
        _stage = AuthStage.onboardingAccount;
      case AuthStage.authenticated:
        return;
    }
    notifyListeners();
  }

  Future<bool> completeOnboarding() async {
    final password = _pendingPassword;
    if (password == null) {
      _setError('Registration session expired. Please create the account again.');
      return false;
    }

    return _submit(() async {
      final session = await repository.register(
        fullName: _displayName,
        email: _email,
        password: password,
        preferredCurrencyCode: _preferredCurrencyCode,
      );
      _applySession(session);
      _stage = AuthStage.authenticated;
      _pendingPassword = null;
    });
  }

  Future<void> signOut() async {
    _errorMessage = null;
    await repository.signOut();
    _session = null;
    _pendingPassword = null;
    _stage = AuthStage.signIn;
    notifyListeners();
  }

  Future<bool> _submit(Future<void> Function() action) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = '$error'.replaceFirst('Bad state: ', '');
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  void _applySession(AuthSession session) {
    _session = session;
    _displayName = session.displayName;
    _email = session.email;
    _preferredCurrencyCode = session.preferredCurrencyCode;
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
