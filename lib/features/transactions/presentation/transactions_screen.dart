import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/features/finance/presentation/widgets/transaction_composer_sheet.dart';
import 'package:money_trace/utils/formatters.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({
    super.key,
    required this.controller,
    required this.settingsController,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

enum _ActivityTab { all, expenses, income, accounts }

class _TransactionsScreenState extends State<TransactionsScreen> {
  late final TextEditingController _searchController;
  final DateFormat _inputDateFormat = DateFormat('dd.MM.yyyy');

  bool _showAdvancedFilters = false;
  _ActivityTab _selectedTab = _ActivityTab.all;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_handleSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        widget.settingsController,
      ]),
      builder: (context, child) {
        final snapshot = widget.controller.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final multiAccountEnabled =
            widget.settingsController.multiAccountModeEnabled;
        final selectedTab =
            !multiAccountEnabled && _selectedTab == _ActivityTab.accounts
            ? _ActivityTab.all
            : _selectedTab;
        final filteredTransactions = _filteredTransactions(snapshot);
        final groupedTransactions = _groupTransactions(filteredTransactions);
        final hasActiveFilters =
            _showAdvancedFilters ||
            selectedTab != _ActivityTab.all ||
            _selectedCategoryId != null ||
            (multiAccountEnabled && _selectedAccountId != null) ||
            _fromDate != null ||
            _toDate != null;

        return Stack(
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF9FBFC), Color(0xFFF5F7FA)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Activity',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                              ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _SearchField(
                                controller: _searchController,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _FilterToggleButton(
                              isActive: hasActiveFilters,
                              onTap: _toggleAdvancedFilters,
                            ),
                          ],
                        ),
                        if (_showAdvancedFilters) ...[
                          const SizedBox(height: 18),
                          _ActivityTabs(
                            selectedTab: selectedTab,
                            showAccounts: multiAccountEnabled,
                            onSelected: _onTabSelected,
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          if (selectedTab == _ActivityTab.expenses) ...[
                            const SizedBox(height: 16),
                            _ChipWrap(
                              chips: [
                                _ChoiceChipData(
                                  label: 'All Expenses',
                                  selected: _selectedCategoryId == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId = null;
                                    });
                                  },
                                ),
                                ..._expenseCategories(snapshot).map(
                                  (category) => _ChoiceChipData(
                                    label: '${category.emoji} ${category.name}',
                                    selected:
                                        _selectedCategoryId == category.id,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryId = category.id;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (selectedTab == _ActivityTab.income) ...[
                            const SizedBox(height: 16),
                            _ChipWrap(
                              chips: [
                                _ChoiceChipData(
                                  label: 'All Income',
                                  selected: _selectedCategoryId == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedCategoryId = null;
                                    });
                                  },
                                ),
                                ..._incomeCategories(snapshot).map(
                                  (category) => _ChoiceChipData(
                                    label: '${category.emoji} ${category.name}',
                                    selected:
                                        _selectedCategoryId == category.id,
                                    onTap: () {
                                      setState(() {
                                        _selectedCategoryId = category.id;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (multiAccountEnabled &&
                              selectedTab == _ActivityTab.accounts) ...[
                            const SizedBox(height: 16),
                            _ChipWrap(
                              chips: [
                                _ChoiceChipData(
                                  label: 'All Accounts',
                                  selected: _selectedAccountId == null,
                                  onTap: () {
                                    setState(() {
                                      _selectedAccountId = null;
                                    });
                                  },
                                ),
                                ...snapshot.accounts.map(
                                  (account) => _ChoiceChipData(
                                    label: account.name,
                                    selected: _selectedAccountId == account.id,
                                    onTap: () {
                                      setState(() {
                                        _selectedAccountId = account.id;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _DateFilterField(
                                  label: 'From',
                                  value: _fromDate == null
                                      ? 'dd.mm.yyyy'
                                      : _inputDateFormat.format(_fromDate!),
                                  onTap: () => _pickDate(isFrom: true),
                                  onClear: _fromDate == null
                                      ? null
                                      : () {
                                          setState(() {
                                            _fromDate = null;
                                          });
                                        },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DateFilterField(
                                  label: 'To',
                                  value: _toDate == null
                                      ? 'dd.mm.yyyy'
                                      : _inputDateFormat.format(_toDate!),
                                  onTap: () => _pickDate(isFrom: false),
                                  onClear: _toDate == null
                                      ? null
                                      : () {
                                          setState(() {
                                            _toDate = null;
                                          });
                                        },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: RefreshIndicator(
                      color: Theme.of(context).colorScheme.primary,
                      onRefresh: widget.controller.load,
                      child: filteredTransactions.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                28,
                                24,
                                140,
                              ),
                              children: const [
                                SizedBox(height: 84),
                                _EmptyActivityState(),
                              ],
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                0,
                                16,
                                140,
                              ),
                              children: [
                                for (final group in groupedTransactions) ...[
                                  _DateSectionHeader(
                                    date: group.date,
                                    total: _sectionTotal(group.transactions),
                                  ),
                                  const SizedBox(height: 10),
                                  for (
                                    var index = 0;
                                    index < group.transactions.length;
                                    index++
                                  ) ...[
                                    _ActivityRecordTile(
                                      transaction: group.transactions[index],
                                      showAccount: multiAccountEnabled,
                                      category: snapshot.findCategory(
                                        group.transactions[index].categoryId,
                                      ),
                                      account: snapshot.findAccount(
                                        group.transactions[index].accountId,
                                      ),
                                    ),
                                    if (index != group.transactions.length - 1)
                                      const SizedBox(height: 12),
                                  ],
                                  const SizedBox(height: 16),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: _ActivityFab(onTap: () => _showQuickActions(snapshot)),
            ),
          ],
        );
      },
    );
  }

  void _handleSearchChanged() {
    setState(() {});
  }

  void _toggleAdvancedFilters() {
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
      if (!_showAdvancedFilters) {
        _resetAdvancedFilters();
      }
    });
  }

  void _onTabSelected(_ActivityTab tab) {
    setState(() {
      _selectedTab = tab;
      _selectedCategoryId = null;
      _selectedAccountId = null;
    });
  }

  void _resetAdvancedFilters() {
    _selectedTab = _ActivityTab.all;
    _selectedCategoryId = null;
    _selectedAccountId = null;
    _fromDate = null;
    _toDate = null;
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initialDate = isFrom ? _fromDate : _toDate;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      if (isFrom) {
        _fromDate = pickedDate;
      } else {
        _toDate = pickedDate;
      }
    });
  }

  Future<void> _showQuickActions(FinanceSnapshot snapshot) async {
    final action = await showModalBottomSheet<_QuickAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _QuickActionSheet(
        showTransfer: widget.settingsController.multiAccountModeEnabled,
      ),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _QuickAction.expense:
        await TransactionComposerSheet.showExpense(
          context,
          controller: widget.controller,
          settingsController: widget.settingsController,
          snapshot: snapshot,
        );
      case _QuickAction.income:
        await TransactionComposerSheet.showIncome(
          context,
          controller: widget.controller,
          settingsController: widget.settingsController,
          snapshot: snapshot,
        );
      case _QuickAction.transfer:
        await TransactionComposerSheet.showTransfer(
          context,
          controller: widget.controller,
          settingsController: widget.settingsController,
          snapshot: snapshot,
        );
    }
  }

  List<FinanceTransaction> _filteredTransactions(FinanceSnapshot snapshot) {
    final query = _searchController.text.trim().toLowerCase();
    final multiAccountEnabled =
        widget.settingsController.multiAccountModeEnabled;
    final selectedTab =
        !multiAccountEnabled && _selectedTab == _ActivityTab.accounts
        ? _ActivityTab.all
        : _selectedTab;
    final selectedAccountId = multiAccountEnabled ? _selectedAccountId : null;

    return snapshot.recentTransactions.where((transaction) {
      final category = snapshot.findCategory(transaction.categoryId);
      final account = snapshot.findAccount(transaction.accountId);

      final matchesSearch =
          query.isEmpty ||
          transaction.title.toLowerCase().contains(query) ||
          transaction.note.toLowerCase().contains(query) ||
          (category?.name.toLowerCase().contains(query) ?? false) ||
          (account?.name.toLowerCase().contains(query) ?? false);

      final matchesTab = switch (selectedTab) {
        _ActivityTab.all => true,
        _ActivityTab.expenses =>
          transaction.type == TransactionType.expense &&
              (_selectedCategoryId == null ||
                  transaction.categoryId == _selectedCategoryId),
        _ActivityTab.income =>
          transaction.type == TransactionType.income &&
              (_selectedCategoryId == null ||
                  transaction.categoryId == _selectedCategoryId),
        _ActivityTab.accounts =>
          selectedAccountId == null ||
              transaction.accountId == selectedAccountId,
      };

      final transactionDay = DateTime(
        transaction.occurredAt.year,
        transaction.occurredAt.month,
        transaction.occurredAt.day,
      );

      final matchesFrom =
          _fromDate == null || !transactionDay.isBefore(_fromDate!);
      final matchesTo = _toDate == null || !transactionDay.isAfter(_toDate!);

      return matchesSearch && matchesTab && matchesFrom && matchesTo;
    }).toList();
  }

  List<_ActivitySection> _groupTransactions(
    List<FinanceTransaction> transactions,
  ) {
    final grouped = <DateTime, List<FinanceTransaction>>{};

    for (final transaction in transactions) {
      final key = DateTime(
        transaction.occurredAt.year,
        transaction.occurredAt.month,
        transaction.occurredAt.day,
      );
      grouped.putIfAbsent(key, () => []).add(transaction);
    }

    final sections =
        grouped.entries
            .map(
              (entry) =>
                  _ActivitySection(date: entry.key, transactions: entry.value),
            )
            .toList()
          ..sort((left, right) => right.date.compareTo(left.date));

    return sections;
  }

  double _sectionTotal(List<FinanceTransaction> transactions) {
    final selectedTab =
        !widget.settingsController.multiAccountModeEnabled &&
            _selectedTab == _ActivityTab.accounts
        ? _ActivityTab.all
        : _selectedTab;

    switch (selectedTab) {
      case _ActivityTab.expenses:
        return transactions
            .where((transaction) => transaction.type == TransactionType.expense)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      case _ActivityTab.income:
        return transactions
            .where((transaction) => transaction.type == TransactionType.income)
            .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      case _ActivityTab.all:
      case _ActivityTab.accounts:
        return transactions.fold<double>(
          0,
          (sum, transaction) => sum + transaction.amount.abs(),
        );
    }
  }

  List<FinanceCategory> _expenseCategories(FinanceSnapshot snapshot) {
    return snapshot.categoriesOfKind(CategoryKind.expense);
  }

  List<FinanceCategory> _incomeCategories(FinanceSnapshot snapshot) {
    return snapshot.categoriesOfKind(CategoryKind.income);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Search activity...',
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF7A889F)),
      ),
    );
  }
}

class _FilterToggleButton extends StatelessWidget {
  const _FilterToggleButton({required this.isActive, required this.onTap});

  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: isActive ? palette.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? palette.primary : const Color(0xFFDCE3EB),
            ),
          ),
          child: Icon(
            Icons.filter_alt_outlined,
            color: isActive ? Colors.white : const Color(0xFF75839A),
          ),
        ),
      ),
    );
  }
}

class _ActivityTabs extends StatelessWidget {
  const _ActivityTabs({
    required this.selectedTab,
    required this.showAccounts,
    required this.onSelected,
  });

  final _ActivityTab selectedTab;
  final bool showAccounts;
  final ValueChanged<_ActivityTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _ActivityTab.all,
      _ActivityTab.expenses,
      _ActivityTab.income,
      if (showAccounts) _ActivityTab.accounts,
    ];

    return Row(
      children: [
        for (final tab in tabs) ...[
          _ActivityTabButton(
            label: tab.label,
            selected: selectedTab == tab,
            onTap: () => onSelected(tab),
          ),
          if (tab != tabs.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _ActivityTabButton extends StatelessWidget {
  const _ActivityTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? palette.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: selected ? palette.primary : const Color(0xFF55657D),
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.chips});

  final List<_ChoiceChipData> chips;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final chip in chips)
          _ActivityChoiceChip(
            label: chip.label,
            selected: chip.selected,
            onTap: chip.onTap,
          ),
      ],
    );
  }
}

class _ChoiceChipData {
  const _ChoiceChipData({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

class _ActivityChoiceChip extends StatelessWidget {
  const _ActivityChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? palette.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.primary : const Color(0xFFDCE3EB),
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF11213F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _DateFilterField extends StatelessWidget {
  const _DateFilterField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final isPlaceholder = value == 'dd.mm.yyyy';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF55657D)),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE3EB)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: isPlaceholder
                            ? const Color(0xFF98A4B8)
                            : const Color(0xFF23324A),
                      ),
                    ),
                  ),
                  if (onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: Color(0xFF8C98AB),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateSectionHeader extends StatelessWidget {
  const _DateSectionHeader({required this.date, required this.total});

  final DateTime date;
  final double total;

  @override
  Widget build(BuildContext context) {
    final totalText = '\$${AppFormatters.groupedNumber(total)}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppFormatters.isoDate(date),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF637797),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            totalText,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF637797),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRecordTile extends StatelessWidget {
  const _ActivityRecordTile({
    required this.transaction,
    required this.showAccount,
    this.category,
    this.account,
  });

  final FinanceTransaction transaction;
  final bool showAccount;
  final FinanceCategory? category;
  final FinanceAccount? account;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final amountText = isIncome
        ? '+\$${AppFormatters.groupedNumber(transaction.amount)}'
        : '-\$${AppFormatters.groupedNumber(transaction.amount)}';
    final subtitleParts = [
      category?.name ?? 'General',
      if (showAccount) account?.name ?? 'Account',
      if (transaction.note.trim().isNotEmpty) transaction.note.trim(),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE3EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0A0F1A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _bubbleColor(category),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              category?.emoji ?? '*',
              style: const TextStyle(fontSize: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14213D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF758399),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF14213D),
            ),
          ),
        ],
      ),
    );
  }

  Color _bubbleColor(FinanceCategory? category) {
    if (category == null) {
      return const Color(0xFFF1F4F8);
    }

    return switch (category.tone) {
      CategoryTone.emerald => const Color(0xFFE9F8EF),
      CategoryTone.amber => const Color(0xFFFFF3E2),
      CategoryTone.coral => const Color(0xFFFCEBE7),
      CategoryTone.sky => const Color(0xFFEAF4FF),
      CategoryTone.plum => const Color(0xFFF3ECFF),
    };
  }
}

class _EmptyActivityState extends StatelessWidget {
  const _EmptyActivityState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFFF2F5FA),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.markunread_mailbox_outlined,
            color: Color(0xFF6678C0),
            size: 30,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'No activity found',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ActivityFab extends StatelessWidget {
  const _ActivityFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: palette.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: palette.primary.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 38, color: Colors.white),
        ),
      ),
    );
  }
}

enum _QuickAction { expense, income, transfer }

class _QuickActionSheet extends StatelessWidget {
  const _QuickActionSheet({required this.showTransfer});

  final bool showTransfer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Action',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _QuickActionTile(
                  icon: Icons.receipt_long_outlined,
                  label: 'Add Expense',
                  onTap: () => Navigator.of(context).pop(_QuickAction.expense),
                ),
                const SizedBox(height: 10),
                _QuickActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Add Income',
                  onTap: () => Navigator.of(context).pop(_QuickAction.income),
                ),
                if (showTransfer) ...[
                  const SizedBox(height: 10),
                  _QuickActionTile(
                    icon: Icons.compare_arrows_rounded,
                    label: 'Transfer',
                    onTap: () =>
                        Navigator.of(context).pop(_QuickAction.transfer),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: palette.primary),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivitySection {
  const _ActivitySection({required this.date, required this.transactions});

  final DateTime date;
  final List<FinanceTransaction> transactions;
}

extension on _ActivityTab {
  String get label {
    switch (this) {
      case _ActivityTab.all:
        return 'All';
      case _ActivityTab.expenses:
        return 'Expenses';
      case _ActivityTab.income:
        return 'Income';
      case _ActivityTab.accounts:
        return 'Accounts';
    }
  }
}
