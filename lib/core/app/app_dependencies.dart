import 'package:money_trace/features/auth/application/auth_controller.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/repositories/money_trace_repository.dart';
import 'package:money_trace/features/finance/domain/services/finance_coach.dart';

class AppDependencies {
  const AppDependencies({
    required this.repository,
    required this.financeCoach,
    required this.financeController,
    required this.authController,
    required this.settingsController,
  });

  final MoneyTraceRepository repository;
  final FinanceCoach financeCoach;
  final FinanceController financeController;
  final AuthController authController;
  final AppSettingsController settingsController;
}
