import 'package:money_trace/data/demo/demo_seed_data.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/features/finance/domain/repositories/money_trace_repository.dart';

class DemoMoneyTraceRepository implements MoneyTraceRepository {
  DemoMoneyTraceRepository()
    : _accounts = List<FinanceAccount>.of(DemoSeedData.accounts()),
      _categories = List<FinanceCategory>.of(DemoSeedData.categories()),
      _templates = List<FinanceTemplate>.of(DemoSeedData.templates()),
      _transactions = List<FinanceTransaction>.of(DemoSeedData.transactions());

  final List<FinanceAccount> _accounts;
  final List<FinanceCategory> _categories;
  final List<FinanceTemplate> _templates;
  final List<FinanceTransaction> _transactions;

  @override
  Future<FinanceSnapshot> loadSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return FinanceSnapshot(
      accounts: List<FinanceAccount>.unmodifiable(_accounts),
      categories: List<FinanceCategory>.unmodifiable(_categories),
      templates: List<FinanceTemplate>.unmodifiable(_templates),
      transactions: List<FinanceTransaction>.unmodifiable(_transactions),
    );
  }

  @override
  Future<void> addAccount(FinanceAccount account) async {
    _accounts.add(account);
  }

  @override
  Future<void> updateAccount(FinanceAccount account) async {
    final index = _accounts.indexWhere(
      (existingAccount) => existingAccount.id == account.id,
    );

    if (index == -1) {
      throw StateError('Account not found.');
    }

    _accounts[index] = account;
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    if (_accounts.isEmpty || _accounts.first.id == accountId) {
      throw StateError('The main account cannot be removed.');
    }

    final hasTransactions = _transactions.any(
      (transaction) => transaction.accountId == accountId,
    );
    if (hasTransactions) {
      throw StateError(
        'Move or delete transactions before removing this account.',
      );
    }

    final hasTemplates = _templates.any(
      (template) => template.accountId == accountId,
    );
    if (hasTemplates) {
      throw StateError(
        'Move or delete templates before removing this account.',
      );
    }

    _accounts.removeWhere((account) => account.id == accountId);
  }

  @override
  Future<void> addCategory(FinanceCategory category) async {
    _categories.add(category);
  }

  @override
  Future<void> updateCategory(FinanceCategory category) async {
    final index = _categories.indexWhere(
      (existingCategory) => existingCategory.id == category.id,
    );

    if (index == -1) {
      throw StateError('Category not found.');
    }

    _categories[index] = category;
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    final hasTransactions = _transactions.any(
      (transaction) => transaction.categoryId == categoryId,
    );
    if (hasTransactions) {
      throw StateError(
        'Delete or reassign transactions before removing this category.',
      );
    }

    final hasTemplates = _templates.any(
      (template) => template.categoryId == categoryId,
    );
    if (hasTemplates) {
      throw StateError(
        'Delete or reassign templates before removing this category.',
      );
    }

    _categories.removeWhere((category) => category.id == categoryId);
  }

  @override
  Future<void> addRecurringTemplate(FinanceTemplate template) async {
    _templates.add(template);
  }

  @override
  Future<void> updateRecurringTemplate(FinanceTemplate template) async {
    final index = _templates.indexWhere(
      (existingTemplate) => existingTemplate.id == template.id,
    );

    if (index == -1) {
      throw StateError('Template not found.');
    }

    _templates[index] = template;
  }

  @override
  Future<void> deleteRecurringTemplate(String templateId) async {
    _templates.removeWhere((template) => template.id == templateId);
  }

  @override
  Future<void> renameTemplateGroup({
    required String oldGroupName,
    required String newGroupName,
  }) async {
    if (newGroupName.trim().isEmpty) {
      throw StateError('Group name cannot be empty.');
    }

    for (var index = 0; index < _templates.length; index++) {
      final template = _templates[index];
      if (template.groupName != oldGroupName) {
        continue;
      }

      _templates[index] = template.copyWith(groupName: newGroupName.trim());
    }
  }

  @override
  Future<void> deleteTemplateGroup(String groupName) async {
    _templates.removeWhere((template) => template.groupName == groupName);
  }

  @override
  Future<void> addTransaction(FinanceTransaction transaction) async {
    _transactions.add(transaction);

    final accountIndex = _accounts.indexWhere(
      (account) => account.id == transaction.accountId,
    );

    if (accountIndex == -1) {
      return;
    }

    final currentAccount = _accounts[accountIndex];
    final delta = switch (transaction.type) {
      TransactionType.income => transaction.amount,
      TransactionType.expense => -transaction.amount,
    };

    _updateAccountBalance(accountIndex, currentAccount.balance + delta);
  }

  @override
  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    if (amount <= 0) {
      throw StateError('Transfer amount must be greater than zero.');
    }

    if (fromAccountId == toAccountId) {
      throw StateError('Select two different accounts for the transfer.');
    }

    final fromIndex = _accounts.indexWhere(
      (account) => account.id == fromAccountId,
    );
    final toIndex = _accounts.indexWhere(
      (account) => account.id == toAccountId,
    );

    if (fromIndex == -1 || toIndex == -1) {
      throw StateError('One of the selected accounts no longer exists.');
    }

    final fromAccount = _accounts[fromIndex];
    final toAccount = _accounts[toIndex];

    if (fromAccount.currencyCode != toAccount.currencyCode) {
      throw StateError(
        'Transfers between different currencies are not available yet.',
      );
    }

    if (fromAccount.balance < amount) {
      throw StateError('Not enough balance in ${fromAccount.name}.');
    }

    _updateAccountBalance(fromIndex, fromAccount.balance - amount);
    _updateAccountBalance(toIndex, toAccount.balance + amount);
  }

  void _updateAccountBalance(int accountIndex, double nextBalance) {
    final currentAccount = _accounts[accountIndex];
    _accounts[accountIndex] = currentAccount.copyWith(balance: nextBalance);
  }
}
