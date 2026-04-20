import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';

abstract interface class MoneyTraceRepository {
  Future<FinanceSnapshot> loadSnapshot();

  Future<void> addTransaction(FinanceTransaction transaction);

  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  });

  Future<void> addRecurringTemplate(FinanceTemplate template);

  Future<void> updateRecurringTemplate(FinanceTemplate template);

  Future<void> deleteRecurringTemplate(String templateId);

  Future<void> renameTemplateGroup({
    required String oldGroupName,
    required String newGroupName,
  });

  Future<void> deleteTemplateGroup(String groupName);

  Future<void> addAccount(FinanceAccount account);

  Future<void> updateAccount(FinanceAccount account);

  Future<void> deleteAccount(String accountId);

  Future<void> addCategory(FinanceCategory category);

  Future<void> updateCategory(FinanceCategory category);

  Future<void> deleteCategory(String categoryId);
}
