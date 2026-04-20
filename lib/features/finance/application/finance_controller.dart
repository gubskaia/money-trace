import 'package:flutter/foundation.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_advice.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/features/finance/domain/repositories/money_trace_repository.dart';
import 'package:money_trace/features/finance/domain/services/finance_coach.dart';

class FinanceController extends ChangeNotifier {
  FinanceController({required this.repository, required this.financeCoach});

  final MoneyTraceRepository repository;
  final FinanceCoach financeCoach;

  FinanceSnapshot? _snapshot;
  bool _isLoading = false;
  String? _errorMessage;

  FinanceSnapshot? get snapshot => _snapshot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<FinanceAdvice> get advice {
    final snapshot = _snapshot;
    if (snapshot == null) {
      return const [];
    }
    return financeCoach.buildAdvice(snapshot);
  }

  Future<void> load() async {
    await _run(() async {
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> addTransaction({
    required String title,
    required double amount,
    required TransactionType type,
    required String accountId,
    required String categoryId,
    String note = '',
  }) async {
    return _run(() async {
      await repository.addTransaction(
        FinanceTransaction(
          id: _buildId('tx'),
          title: title.trim(),
          amount: amount.abs(),
          type: type,
          accountId: accountId,
          categoryId: categoryId,
          occurredAt: DateTime.now(),
          note: note.trim(),
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    return _run(() async {
      await repository.transferBetweenAccounts(
        fromAccountId: fromAccountId,
        toAccountId: toAccountId,
        amount: amount.abs(),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> addRecurringTemplate({
    required String title,
    required double amount,
    required String accountId,
    required String categoryId,
    required String groupName,
    required RecurrenceInterval interval,
    String note = '',
  }) async {
    return _run(() async {
      await repository.addRecurringTemplate(
        FinanceTemplate(
          id: _buildId('tpl'),
          title: title.trim(),
          amount: amount.abs(),
          accountId: accountId,
          categoryId: categoryId,
          groupName: groupName.trim(),
          interval: interval,
          note: note.trim(),
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> updateRecurringTemplate({
    required String id,
    required String title,
    required double amount,
    required String accountId,
    required String categoryId,
    required String groupName,
    required RecurrenceInterval interval,
    String note = '',
  }) async {
    return _run(() async {
      await repository.updateRecurringTemplate(
        FinanceTemplate(
          id: id,
          title: title.trim(),
          amount: amount.abs(),
          accountId: accountId,
          categoryId: categoryId,
          groupName: groupName.trim(),
          interval: interval,
          note: note.trim(),
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> deleteRecurringTemplate(String templateId) async {
    return _run(() async {
      await repository.deleteRecurringTemplate(templateId);
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> renameTemplateGroup({
    required String oldGroupName,
    required String newGroupName,
  }) async {
    return _run(() async {
      await repository.renameTemplateGroup(
        oldGroupName: oldGroupName,
        newGroupName: newGroupName.trim(),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> deleteTemplateGroup(String groupName) async {
    return _run(() async {
      await repository.deleteTemplateGroup(groupName);
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> addAccount({
    required String name,
    required double openingBalance,
    required AccountKind kind,
    String currencyCode = 'KZT',
    int accentColorValue = 0xFF58BE83,
  }) async {
    return _run(() async {
      await repository.addAccount(
        FinanceAccount(
          id: _buildId('acc'),
          name: name.trim(),
          kind: kind,
          balance: openingBalance,
          currencyCode: currencyCode,
          accentColorValue: accentColorValue,
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> updateAccount({
    required String id,
    required String name,
    required double balance,
    required String currencyCode,
    required int accentColorValue,
  }) async {
    return _run(() async {
      final currentAccount = _snapshot?.findAccount(id);
      if (currentAccount == null) {
        throw StateError('Account not found.');
      }

      await repository.updateAccount(
        currentAccount.copyWith(
          name: name.trim(),
          balance: balance,
          currencyCode: currencyCode.trim().toUpperCase(),
          accentColorValue: accentColorValue,
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> deleteAccount(String accountId) async {
    return _run(() async {
      await repository.deleteAccount(accountId);
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> addCategory({required String name, String? emoji}) async {
    return _run(() async {
      await repository.addCategory(
        FinanceCategory(
          id: _buildId('cat'),
          name: name.trim(),
          emoji: (emoji == null || emoji.trim().isEmpty)
              ? _suggestEmoji(name)
              : emoji.trim(),
          tone: _nextTone(),
          kind: CategoryKind.expense,
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> addManagedCategory({
    required String name,
    required CategoryKind kind,
    String? emoji,
  }) async {
    return _run(() async {
      await repository.addCategory(
        FinanceCategory(
          id: _buildId('cat'),
          name: name.trim(),
          emoji: (emoji == null || emoji.trim().isEmpty)
              ? _suggestEmoji(name)
              : emoji.trim(),
          tone: _nextTone(),
          kind: kind,
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> updateCategory({
    required String id,
    required String name,
    required CategoryKind kind,
    String? emoji,
  }) async {
    return _run(() async {
      final currentCategory = _snapshot?.findCategory(id);
      if (currentCategory == null) {
        throw StateError('Category not found.');
      }

      await repository.updateCategory(
        currentCategory.copyWith(
          name: name.trim(),
          emoji: (emoji == null || emoji.trim().isEmpty)
              ? _suggestEmoji(name)
              : emoji.trim(),
          kind: kind,
        ),
      );
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> deleteCategory(String categoryId) async {
    return _run(() async {
      await repository.deleteCategory(categoryId);
      _snapshot = await repository.loadSnapshot();
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error) {
      _errorMessage = 'Unable to update data: $error';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _buildId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  CategoryTone _nextTone() {
    final categoriesCount = _snapshot?.categories.length ?? 0;
    return CategoryTone.values[categoriesCount % CategoryTone.values.length];
  }

  String _suggestEmoji(String rawName) {
    final name = rawName.toLowerCase();

    if (name.contains('food') ||
        name.contains('grocery') ||
        name.contains('dining')) {
      return '🍽️';
    }
    if (name.contains('home') ||
        name.contains('rent') ||
        name.contains('house')) {
      return '🏠';
    }
    if (name.contains('transport') ||
        name.contains('taxi') ||
        name.contains('uber')) {
      return '🚗';
    }
    if (name.contains('health') ||
        name.contains('pharmacy') ||
        name.contains('medical')) {
      return '💊';
    }
    if (name.contains('salary') ||
        name.contains('work') ||
        name.contains('job')) {
      return '💼';
    }
    if (name.contains('gift') ||
        name.contains('income') ||
        name.contains('bonus')) {
      return '🎁';
    }
    if (name.contains('travel')) {
      return '✈️';
    }

    return '🧩';
  }
}
