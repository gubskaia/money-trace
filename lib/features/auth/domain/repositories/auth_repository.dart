import 'package:money_trace/features/auth/domain/models/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession?> restoreSession();

  Future<bool> emailExists(String email);

  Future<AuthSession> signIn({
    required String email,
    required String password,
  });

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String preferredCurrencyCode,
  });

  Future<void> signOut();
}
