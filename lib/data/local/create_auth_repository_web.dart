import 'package:money_trace/data/demo/memory_auth_repository.dart';
import 'package:money_trace/features/auth/domain/repositories/auth_repository.dart';

Future<AuthRepository> createAuthRepository() async {
  return MemoryAuthRepository();
}
