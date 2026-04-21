import 'package:money_trace/data/local/password_hasher.dart';
import 'package:money_trace/features/auth/domain/models/auth_session.dart';
import 'package:money_trace/features/auth/domain/repositories/auth_repository.dart';

class MemoryAuthRepository implements AuthRepository {
  MemoryAuthRepository({bool seedDemoUser = true}) {
    if (seedDemoUser) {
      final digest = PasswordHasher.hashPassword('1234');
      _users[_normalizeEmail('alex@moneytrace.app')] = _StoredUser(
        id: 'usr-demo',
        displayName: 'Alex Kowalski',
        email: _normalizeEmail('alex@moneytrace.app'),
        preferredCurrencyCode: 'KZT',
        passwordSalt: digest.salt,
        passwordHash: digest.hash,
      );
    }
  }

  final Map<String, _StoredUser> _users = <String, _StoredUser>{};
  AuthSession? _session;

  @override
  Future<AuthSession?> restoreSession() async {
    return _session;
  }

  @override
  Future<bool> emailExists(String email) async {
    return _users.containsKey(_normalizeEmail(email));
  }

  @override
  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    final user = _users[normalizedEmail];
    if (user == null ||
        !PasswordHasher.verify(
          password: password,
          salt: user.passwordSalt,
          expectedHash: user.passwordHash,
        )) {
      throw StateError('Incorrect email or password.');
    }

    final session = user.toSession();
    _session = session;
    return session;
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String preferredCurrencyCode,
  }) async {
    final normalizedEmail = _normalizeEmail(email);
    if (_users.containsKey(normalizedEmail)) {
      throw StateError('An account with this email already exists.');
    }

    final digest = PasswordHasher.hashPassword(password);
    final user = _StoredUser(
      id: 'usr-${DateTime.now().microsecondsSinceEpoch}',
      displayName: fullName.trim(),
      email: normalizedEmail,
      preferredCurrencyCode: preferredCurrencyCode.trim().toUpperCase(),
      passwordSalt: digest.salt,
      passwordHash: digest.hash,
    );
    _users[normalizedEmail] = user;
    final session = user.toSession();
    _session = session;
    return session;
  }

  @override
  Future<void> signOut() async {
    _session = null;
  }

  String _normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }
}

class _StoredUser {
  const _StoredUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.preferredCurrencyCode,
    required this.passwordSalt,
    required this.passwordHash,
  });

  final String id;
  final String displayName;
  final String email;
  final String preferredCurrencyCode;
  final String passwordSalt;
  final String passwordHash;

  AuthSession toSession() {
    return AuthSession(
      userId: id,
      displayName: displayName,
      email: email,
      preferredCurrencyCode: preferredCurrencyCode,
    );
  }
}
