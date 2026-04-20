import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_trace/core/theme/app_theme.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';
import 'package:money_trace/data/demo/demo_money_trace_repository.dart';
import 'package:money_trace/data/demo/rule_based_finance_coach.dart';
import 'package:money_trace/features/auth/application/auth_controller.dart';
import 'package:money_trace/features/auth/presentation/auth_flow_screen.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';

void main() {
  group('FinanceController', () {
    test('loads seed snapshot and produces advice', () async {
      final controller = FinanceController(
        repository: DemoMoneyTraceRepository(),
        financeCoach: RuleBasedFinanceCoach(),
      );

      await controller.load();

      expect(controller.snapshot, isNotNull);
      expect(controller.snapshot!.accounts, isNotEmpty);
      expect(controller.snapshot!.templates, isNotEmpty);
      expect(controller.snapshot!.transactions, isNotEmpty);
      expect(controller.advice, isNotEmpty);
    });

    test('adds transaction into snapshot', () async {
      final controller = FinanceController(
        repository: DemoMoneyTraceRepository(),
        financeCoach: RuleBasedFinanceCoach(),
      );

      await controller.load();
      final initialTransactionsCount = controller.snapshot!.transactions.length;
      final snapshot = controller.snapshot!;

      await controller.addTransaction(
        title: 'Test transaction',
        amount: 5000,
        type: TransactionType.expense,
        accountId: snapshot.accounts.first.id,
        categoryId: snapshot.categories.first.id,
      );

      expect(
        controller.snapshot!.transactions.length,
        initialTransactionsCount + 1,
      );
    });

    test('adds recurring template into snapshot', () async {
      final controller = FinanceController(
        repository: DemoMoneyTraceRepository(),
        financeCoach: RuleBasedFinanceCoach(),
      );

      await controller.load();
      final initialTemplatesCount = controller.snapshot!.templates.length;
      final snapshot = controller.snapshot!;

      await controller.addRecurringTemplate(
        title: 'Water bill',
        amount: 12,
        accountId: snapshot.accounts.first.id,
        categoryId: 'cat-bills',
        groupName: 'Utilities',
        interval: RecurrenceInterval.monthly,
      );

      expect(controller.snapshot!.templates.length, initialTemplatesCount + 1);
    });

    test('updates and deletes recurring templates', () async {
      final controller = FinanceController(
        repository: DemoMoneyTraceRepository(),
        financeCoach: RuleBasedFinanceCoach(),
      );

      await controller.load();
      final initialTemplate = controller.snapshot!.templates.first;

      await controller.updateRecurringTemplate(
        id: initialTemplate.id,
        title: 'Netflix Premium',
        amount: 11,
        accountId: initialTemplate.accountId,
        categoryId: initialTemplate.categoryId,
        groupName: 'Subscriptions',
        interval: RecurrenceInterval.monthly,
        note: 'Updated',
      );

      expect(controller.snapshot!.templates.first.title, 'Netflix Premium');

      await controller.deleteRecurringTemplate(initialTemplate.id);

      expect(
        controller.snapshot!.templates.any(
          (template) => template.id == initialTemplate.id,
        ),
        isFalse,
      );
    });
  });

  group('AuthController', () {
    test('sign in authenticates with valid credentials', () async {
      final controller = AuthController();

      final success = await controller.signIn(
        email: 'elisei@example.com',
        password: '1234',
      );

      expect(success, isTrue);
      expect(controller.isAuthenticated, isTrue);
      expect(controller.displayName, 'Elisei');
    });

    test('registration advances through onboarding', () async {
      final controller = AuthController();

      final started = await controller.startRegistration(
        fullName: 'Elisei Dev',
        email: 'elisei@example.com',
        password: '1234',
      );

      expect(started, isTrue);
      expect(controller.stage, AuthStage.onboardingCurrency);

      controller.selectCurrency('USD');
      controller.goToAccountSetup();
      final saved = await controller.saveStarterAccount(
        accountName: 'Main Wallet',
        openingBalance: 320,
      );

      expect(saved, isTrue);
      expect(controller.stage, AuthStage.onboardingComplete);
      expect(controller.preferredCurrencyCode, 'USD');
      expect(controller.starterBalance, 320);
    });
  });

  testWidgets('AuthFlowScreen builds the sign in stage without layout errors', (
    tester,
  ) async {
    final authController = AuthController();
    final financeController = FinanceController(
      repository: DemoMoneyTraceRepository(),
      financeCoach: RuleBasedFinanceCoach(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(preset: AppThemePreset.emerald),
        home: AuthFlowScreen(
          authController: authController,
          financeController: financeController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome back to MoneyTrace'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
