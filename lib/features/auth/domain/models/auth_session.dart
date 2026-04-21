class AuthSession {
  const AuthSession({
    required this.userId,
    required this.displayName,
    required this.email,
    required this.preferredCurrencyCode,
  });

  final String userId;
  final String displayName;
  final String email;
  final String preferredCurrencyCode;
}
