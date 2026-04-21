import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';

abstract interface class MoneyTraceRepository {
  Future<FinanceSnapshot> loadSnapshot({required String userId});

  Future<void> bootstrapUserWorkspace({
    required String userId,
    required String accountName,
    required double openingBalance,
    required String currencyCode,
  });

  Future<void> addTransaction({
    required String userId,
    required FinanceTransaction transaction,
  });

  Future<void> transferBetweenAccounts({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  });

  Future<void> addRecurringTemplate({
    required String userId,
    required FinanceTemplate template,
  });

  Future<void> updateRecurringTemplate({
    required String userId,
    required FinanceTemplate template,
  });

  Future<void> deleteRecurringTemplate({
    required String userId,
    required String templateId,
  });

  Future<void> renameTemplateGroup({
    required String userId,
    required String oldGroupName,
    required String newGroupName,
  });

  Future<void> deleteTemplateGroup({
    required String userId,
    required String groupName,
  });

  Future<void> addAccount({
    required String userId,
    required FinanceAccount account,
  });

  Future<void> updateAccount({
    required String userId,
    required FinanceAccount account,
  });

  Future<void> deleteAccount({
    required String userId,
    required String accountId,
  });

  Future<void> addCategory({
    required String userId,
    required FinanceCategory category,
  });

  Future<void> updateCategory({
    required String userId,
    required FinanceCategory category,
  });

  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  });
}
