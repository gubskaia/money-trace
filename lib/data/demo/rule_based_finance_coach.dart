import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_advice.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/services/finance_coach.dart';
import 'package:money_trace/utils/formatters.dart';

class RuleBasedFinanceCoach implements FinanceCoach {
  @override
  List<FinanceAdvice> buildAdvice(FinanceSnapshot snapshot) {
    if (snapshot.transactions.isEmpty) {
      return const [
        FinanceAdvice(
          title: 'Start with a few transactions',
          message:
              'As soon as your app has expenses and income, the coach can start generating useful suggestions.',
          tone: AdviceTone.info,
        ),
      ];
    }

    final advice = <FinanceAdvice>[];
    final income = snapshot.incomeThisMonth;
    final expenses = snapshot.expensesThisMonth;
    final expenseByCategory = snapshot.expenseByCategory;

    if (expenseByCategory.isNotEmpty && expenses > 0) {
      String dominantCategoryId = '';
      double dominantAmount = 0;

      for (final entry in expenseByCategory.entries) {
        if (entry.value > dominantAmount) {
          dominantCategoryId = entry.key;
          dominantAmount = entry.value;
        }
      }

      final share = dominantAmount / expenses;
      final categoryName = snapshot.findCategory(dominantCategoryId)?.name;

      if (categoryName == 'Food' && share >= 0.30) {
        advice.add(
          FinanceAdvice(
            title: 'Reduce dining expenses',
            message:
                'Your food spending now makes up ${(share * 100).round()}% of this month\'s expenses. Consider cooking at home a bit more often.',
            tone: AdviceTone.warning,
          ),
        );
      } else if (share >= 0.30 && categoryName != null) {
        advice.add(
          FinanceAdvice(
            title: 'Watch your $categoryName spending',
            message:
                '$categoryName already represents ${(share * 100).round()}% of this month\'s outflow. This is a good category to review first.',
            tone: AdviceTone.info,
          ),
        );
      }
    }

    if (expenses > income && income > 0) {
      advice.add(
        FinanceAdvice(
          title: 'Expenses are outrunning income',
          message:
              'This month is currently negative by ${AppFormatters.money(expenses - income, currencyCode: snapshot.reportingCurrencyCode)}. It may be worth trimming one flexible category.',
          tone: AdviceTone.warning,
        ),
      );
    }

    final reserveAccounts = snapshot.accounts
        .where((account) => account.kind == AccountKind.savings)
        .toList();
    final reserveBalance = reserveAccounts.fold<double>(
      0,
      (sum, account) => sum + snapshot.convertedAccountBalance(account),
    );

    if (reserveAccounts.isEmpty) {
      advice.add(
        const FinanceAdvice(
          title: 'Open a reserve wallet',
          message:
              'Even one dedicated savings account makes your cash buffer much easier to track.',
          tone: AdviceTone.info,
        ),
      );
    } else if (reserveBalance < expenses * 2 && expenses > 0) {
      advice.add(
        const FinanceAdvice(
          title: 'Your reserve can grow further',
          message:
              'A strong next milestone is building the reserve up to at least two months of expenses.',
          tone: AdviceTone.warning,
        ),
      );
    } else {
      advice.add(
        const FinanceAdvice(
          title: 'Your reserve looks healthy',
          message:
              'You already have a separate savings layer, which is a solid base for smarter AI suggestions later on.',
          tone: AdviceTone.success,
        ),
      );
    }

    if (snapshot.netFlowThisMonth > 0) {
      advice.add(
        FinanceAdvice(
          title: 'You are still positive this month',
          message:
              'You currently have about ${AppFormatters.money(snapshot.netFlowThisMonth, currencyCode: snapshot.reportingCurrencyCode)} left after expenses. Part of it could be moved into savings automatically.',
          tone: AdviceTone.success,
        ),
      );
    }

    return advice.take(4).toList();
  }
}
