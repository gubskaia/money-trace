import 'package:money_trace/data/demo/demo_seed_data.dart';
import 'package:money_trace/features/finance/domain/models/currency_converter.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/features/finance/domain/repositories/money_trace_repository.dart';

class DemoMoneyTraceRepository implements MoneyTraceRepository {
  final Map<String, _DemoFinanceStore> _stores = <String, _DemoFinanceStore>{};

  @override
  Future<FinanceSnapshot> loadSnapshot({required String userId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final store = _storeFor(userId);
    return FinanceSnapshot(
      accounts: List<FinanceAccount>.unmodifiable(store.accounts),
      categories: List<FinanceCategory>.unmodifiable(store.categories),
      templates: List<FinanceTemplate>.unmodifiable(store.templates),
      transactions: List<FinanceTransaction>.unmodifiable(store.transactions),
      converter: CurrencyConverter(
        reportingCurrencyCode: store.reportingCurrencyCode,
        ratesToBase: defaultExchangeRatesToBase,
      ),
    );
  }

  @override
  Future<void> bootstrapUserWorkspace({
    required String userId,
    required String accountName,
    required double openingBalance,
    required String currencyCode,
  }) async {
    final store = _storeFor(userId);
    if (store.accounts.isNotEmpty) {
      return;
    }

    store.accounts.add(
      FinanceAccount(
        id: 'acc-main',
        name: accountName.trim(),
        kind: AccountKind.card,
        balance: openingBalance,
        currencyCode: currencyCode.trim().toUpperCase(),
      ),
    );
    store.reportingCurrencyCode = currencyCode.trim().toUpperCase();
    store.categories.addAll(DemoSeedData.categories());
  }

  @override
  Future<void> addTransaction({
    required String userId,
    required FinanceTransaction transaction,
  }) async {
    final store = _storeFor(userId);
    store.transactions.add(transaction);

    final accountIndex = store.accounts.indexWhere(
      (account) => account.id == transaction.accountId,
    );
    if (accountIndex == -1) {
      return;
    }

    final currentAccount = store.accounts[accountIndex];
    final delta = switch (transaction.type) {
      TransactionType.income => transaction.amount,
      TransactionType.expense => -transaction.amount,
    };
    store.accounts[accountIndex] = currentAccount.copyWith(
      balance: currentAccount.balance + delta,
    );
  }

  @override
  Future<void> transferBetweenAccounts({
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    final store = _storeFor(userId);

    if (amount <= 0) {
      throw StateError('Transfer amount must be greater than zero.');
    }

    if (fromAccountId == toAccountId) {
      throw StateError('Select two different accounts for the transfer.');
    }

    final fromIndex = store.accounts.indexWhere(
      (account) => account.id == fromAccountId,
    );
    final toIndex = store.accounts.indexWhere((account) => account.id == toAccountId);
    if (fromIndex == -1 || toIndex == -1) {
      throw StateError('One of the selected accounts no longer exists.');
    }

    final fromAccount = store.accounts[fromIndex];
    final toAccount = store.accounts[toIndex];
    if (fromAccount.currencyCode != toAccount.currencyCode) {
      throw StateError(
        'Transfers between different currencies are not available yet.',
      );
    }

    if (fromAccount.balance < amount) {
      throw StateError('Not enough balance in ${fromAccount.name}.');
    }

    store.accounts[fromIndex] = fromAccount.copyWith(
      balance: fromAccount.balance - amount,
    );
    store.accounts[toIndex] = toAccount.copyWith(
      balance: toAccount.balance + amount,
    );
  }

  @override
  Future<void> addRecurringTemplate({
    required String userId,
    required FinanceTemplate template,
  }) async {
    _storeFor(userId).templates.add(template);
  }

  @override
  Future<void> updateRecurringTemplate({
    required String userId,
    required FinanceTemplate template,
  }) async {
    final store = _storeFor(userId);
    final index = store.templates.indexWhere(
      (existingTemplate) => existingTemplate.id == template.id,
    );
    if (index == -1) {
      throw StateError('Template not found.');
    }

    store.templates[index] = template;
  }

  @override
  Future<void> deleteRecurringTemplate({
    required String userId,
    required String templateId,
  }) async {
    _storeFor(userId).templates.removeWhere(
      (template) => template.id == templateId,
    );
  }

  @override
  Future<void> renameTemplateGroup({
    required String userId,
    required String oldGroupName,
    required String newGroupName,
  }) async {
    if (newGroupName.trim().isEmpty) {
      throw StateError('Group name cannot be empty.');
    }

    final store = _storeFor(userId);
    for (var index = 0; index < store.templates.length; index++) {
      final template = store.templates[index];
      if (template.groupName != oldGroupName) {
        continue;
      }
      store.templates[index] = template.copyWith(groupName: newGroupName.trim());
    }
  }

  @override
  Future<void> deleteTemplateGroup({
    required String userId,
    required String groupName,
  }) async {
    _storeFor(userId).templates.removeWhere(
      (template) => template.groupName == groupName,
    );
  }

  @override
  Future<void> addAccount({
    required String userId,
    required FinanceAccount account,
  }) async {
    _storeFor(userId).accounts.add(account);
  }

  @override
  Future<void> updateAccount({
    required String userId,
    required FinanceAccount account,
  }) async {
    final store = _storeFor(userId);
    final index = store.accounts.indexWhere(
      (existingAccount) => existingAccount.id == account.id,
    );
    if (index == -1) {
      throw StateError('Account not found.');
    }

    store.accounts[index] = account;
  }

  @override
  Future<void> deleteAccount({
    required String userId,
    required String accountId,
  }) async {
    final store = _storeFor(userId);
    if (store.accounts.isEmpty || store.accounts.first.id == accountId) {
      throw StateError('The main account cannot be removed.');
    }

    if (store.transactions.any((transaction) => transaction.accountId == accountId)) {
      throw StateError(
        'Move or delete transactions before removing this account.',
      );
    }

    if (store.templates.any((template) => template.accountId == accountId)) {
      throw StateError('Move or delete templates before removing this account.');
    }

    store.accounts.removeWhere((account) => account.id == accountId);
  }

  @override
  Future<void> addCategory({
    required String userId,
    required FinanceCategory category,
  }) async {
    _storeFor(userId).categories.add(category);
  }

  @override
  Future<void> updateCategory({
    required String userId,
    required FinanceCategory category,
  }) async {
    final store = _storeFor(userId);
    final index = store.categories.indexWhere(
      (existingCategory) => existingCategory.id == category.id,
    );
    if (index == -1) {
      throw StateError('Category not found.');
    }

    store.categories[index] = category;
  }

  @override
  Future<void> deleteCategory({
    required String userId,
    required String categoryId,
  }) async {
    final store = _storeFor(userId);
    if (store.transactions.any((transaction) => transaction.categoryId == categoryId)) {
      throw StateError(
        'Delete or reassign transactions before removing this category.',
      );
    }

    if (store.templates.any((template) => template.categoryId == categoryId)) {
      throw StateError(
        'Delete or reassign templates before removing this category.',
      );
    }

    store.categories.removeWhere((category) => category.id == categoryId);
  }

  _DemoFinanceStore _storeFor(String userId) {
    return _stores.putIfAbsent(
      userId,
      () => _DemoFinanceStore.seeded(),
    );
  }
}

class _DemoFinanceStore {
  _DemoFinanceStore({
    required this.accounts,
    required this.categories,
    required this.templates,
    required this.transactions,
    required this.reportingCurrencyCode,
  });

  factory _DemoFinanceStore.seeded() {
    return _DemoFinanceStore(
      accounts: List<FinanceAccount>.of(DemoSeedData.accounts()),
      categories: List<FinanceCategory>.of(DemoSeedData.categories()),
      templates: List<FinanceTemplate>.of(DemoSeedData.templates()),
      transactions: List<FinanceTransaction>.of(DemoSeedData.transactions()),
      reportingCurrencyCode: 'KZT',
    );
  }

  final List<FinanceAccount> accounts;
  final List<FinanceCategory> categories;
  final List<FinanceTemplate> templates;
  final List<FinanceTransaction> transactions;
  String reportingCurrencyCode;
}
