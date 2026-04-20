import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_trace/core/app/app.dart';
import 'package:money_trace/core/app/app_dependencies.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/data/demo/demo_money_trace_repository.dart';
import 'package:money_trace/data/demo/rule_based_finance_coach.dart';
import 'package:money_trace/features/auth/application/auth_controller.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';

Future<Widget> bootstrapApp() async {
  await initializeDateFormatting('en_US');

  final repository = DemoMoneyTraceRepository();
  final financeCoach = RuleBasedFinanceCoach();
  final authController = AuthController();
  final settingsController = AppSettingsController();
  final financeController = FinanceController(
    repository: repository,
    financeCoach: financeCoach,
  );

  await financeController.load();

  return MoneyTraceApp(
    dependencies: AppDependencies(
      repository: repository,
      financeCoach: financeCoach,
      financeController: financeController,
      authController: authController,
      settingsController: settingsController,
    ),
  );
}
