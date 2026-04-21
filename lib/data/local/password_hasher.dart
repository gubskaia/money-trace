import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

class PasswordDigest {
  const PasswordDigest({required this.salt, required this.hash});

  final String salt;
  final String hash;
}

abstract final class PasswordHasher {
  static const _iterations = 4096;
  static final Random _random = Random.secure();

  static PasswordDigest hashPassword(String password) {
    final saltBytes = Uint8List.fromList(
      List<int>.generate(16, (_) => _random.nextInt(256)),
    );
    final salt = base64UrlEncode(saltBytes);
    return PasswordDigest(
      salt: salt,
      hash: _deriveHash(password: password, salt: salt),
    );
  }

  static bool verify({
    required String password,
    required String salt,
    required String expectedHash,
  }) {
    final candidateHash = _deriveHash(password: password, salt: salt);
    return _constantTimeEquals(candidateHash, expectedHash);
  }

  static String _deriveHash({
    required String password,
    required String salt,
  }) {
    var bytes = Uint8List.fromList(utf8.encode('$salt::$password'));
    for (var index = 0; index < _iterations; index++) {
      bytes = Uint8List.fromList(sha256.convert(bytes).bytes);
    }
    return base64UrlEncode(bytes);
  }

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length) {
      return false;
    }

    var mismatch = 0;
    for (var index = 0; index < left.length; index++) {
      mismatch |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return mismatch == 0;
  }
}
