import 'package:flutter/foundation.dart';

enum AuthStage {
  signIn,
  signUp,
  onboardingCurrency,
  onboardingAccount,
  onboardingComplete,
  authenticated,
}

class AuthController extends ChangeNotifier {
  AuthStage _stage = AuthStage.signIn;
  String _displayName = 'Alex Kowalski';
  String _email = 'alex@moneytrace.app';
  String _preferredCurrencyCode = 'KZT';
  String _starterAccountName = 'Main Wallet';
  double _starterBalance = 0;
  bool _isSubmitting = false;
  String? _errorMessage;

  AuthStage get stage => _stage;
  String get displayName => _displayName;
  String get email => _email;
  String get preferredCurrencyCode => _preferredCurrencyCode;
  String get starterAccountName => _starterAccountName;
  double get starterBalance => _starterBalance;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _stage == AuthStage.authenticated;

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

  void showSignIn() {
    _errorMessage = null;
    _stage = AuthStage.signIn;
    notifyListeners();
  }

  void showSignUp() {
    _errorMessage = null;
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
      await Future<void>.delayed(const Duration(milliseconds: 340));
      _email = trimmedEmail;
      _displayName = _nameFromEmail(trimmedEmail);
      _stage = AuthStage.authenticated;
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
      await Future<void>.delayed(const Duration(milliseconds: 360));
      _displayName = trimmedName;
      _email = trimmedEmail;
      _preferredCurrencyCode = 'KZT';
      _starterAccountName = 'Main Wallet';
      _starterBalance = 0;
      _stage = AuthStage.onboardingCurrency;
    });
  }

  void selectCurrency(String currencyCode) {
    _errorMessage = null;
    _preferredCurrencyCode = currencyCode;
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
      await Future<void>.delayed(const Duration(milliseconds: 260));
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

  void completeOnboarding() {
    _errorMessage = null;
    _stage = AuthStage.authenticated;
    notifyListeners();
  }

  void signOut() {
    _errorMessage = null;
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
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }

  String _nameFromEmail(String value) {
    final localPart = value.split('@').first.trim();
    if (localPart.isEmpty) {
      return 'MoneyTrace User';
    }

    final words = localPart
        .split(RegExp(r'[._-]+'))
        .where((word) => word.isNotEmpty)
        .map(_capitalize)
        .toList();

    if (words.isEmpty) {
      return 'MoneyTrace User';
    }

    return words.join(' ');
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
