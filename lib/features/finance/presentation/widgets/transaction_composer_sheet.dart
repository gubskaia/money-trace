import 'package:flutter/material.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/utils/formatters.dart';
import 'package:money_trace/utils/grouped_amount_input_formatter.dart';

abstract final class TransactionComposerSheet {
  static Future<void> showIncome(
    BuildContext context, {
    required FinanceController controller,
    required AppSettingsController settingsController,
    required FinanceSnapshot snapshot,
  }) {
    return _show(
      context,
      child: _IncomeComposerSheet(
        controller: controller,
        settingsController: settingsController,
        snapshot: snapshot,
      ),
    );
  }

  static Future<void> showExpense(
    BuildContext context, {
    required FinanceController controller,
    required AppSettingsController settingsController,
    required FinanceSnapshot snapshot,
  }) {
    return _show(
      context,
      child: _ExpenseComposerSheet(
        controller: controller,
        settingsController: settingsController,
        snapshot: snapshot,
      ),
    );
  }

  static Future<void> showTransfer(
    BuildContext context, {
    required FinanceController controller,
    required AppSettingsController settingsController,
    required FinanceSnapshot snapshot,
  }) {
    if (!settingsController.multiAccountModeEnabled) {
      return Future<void>.value();
    }

    return _show(
      context,
      child: _TransferComposerSheet(controller: controller, snapshot: snapshot),
    );
  }

  static Future<void> _show(BuildContext context, {required Widget child}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (context) => child,
    );
  }
}

class _IncomeComposerSheet extends StatefulWidget {
  const _IncomeComposerSheet({
    required this.controller,
    required this.settingsController,
    required this.snapshot,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;
  final FinanceSnapshot snapshot;

  @override
  State<_IncomeComposerSheet> createState() => _IncomeComposerSheetState();
}

class _IncomeComposerSheetState extends State<_IncomeComposerSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final List<FinanceCategory> _categories;
  late String _selectedCategoryId;
  late String _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _categories = _buildCategorySelection(
      widget.snapshot,
      kind: CategoryKind.income,
    );
    _selectedCategoryId = _categories.first.id;
    _selectedAccountId =
        widget.snapshot.primaryAccount?.id ?? widget.snapshot.accounts.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiAccountEnabled =
        widget.settingsController.multiAccountModeEnabled;

    return _FinanceSheetScaffold(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Add Income',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'Amount'),
          const SizedBox(height: 10),
          _AmountField(
            controller: _amountController,
            prefix: '+ ${_selectedAccount.currencyCode}',
            accentColor: AppColors.income,
          ),
          const SizedBox(height: 18),
          _FieldLabel(text: 'Description'),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Where did this income come from?',
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel(text: 'Source'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final category in _categories)
                _CategoryOptionChip(
                  category: category,
                  selected: _selectedCategoryId == category.id,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                  },
                ),
            ],
          ),
          if (multiAccountEnabled) ...[
            const SizedBox(height: 18),
            _FieldLabel(text: 'Account'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final account in widget.snapshot.accounts)
                  _AccountOptionChip(
                    account: account,
                    selected: _selectedAccountId == account.id,
                    onTap: () {
                      setState(() {
                        _selectedAccountId = account.id;
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Add Income'),
            ),
          ),
        ],
      ),
    );
  }

  FinanceAccount get _selectedAccount =>
      widget.snapshot.findAccount(_selectedAccountId) ??
      widget.snapshot.primaryAccount ??
      widget.snapshot.accounts.first;

  Future<void> _submit() async {
    final title = _descriptionController.text.trim();
    final amount = _parseAmount(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) {
      _showError('Enter a description and a valid amount.');
      return;
    }

    final success = await widget.controller.addTransaction(
      title: title,
      amount: amount,
      type: TransactionType.income,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(widget.controller.errorMessage ?? 'Unable to add income.');
      return;
    }

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ExpenseComposerSheet extends StatefulWidget {
  const _ExpenseComposerSheet({
    required this.controller,
    required this.settingsController,
    required this.snapshot,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;
  final FinanceSnapshot snapshot;

  @override
  State<_ExpenseComposerSheet> createState() => _ExpenseComposerSheetState();
}

class _ExpenseComposerSheetState extends State<_ExpenseComposerSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final List<FinanceCategory> _categories;
  late String _selectedCategoryId;
  late String _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _categories = _buildCategorySelection(
      widget.snapshot,
      kind: CategoryKind.expense,
    );
    _selectedCategoryId = _categories.first.id;
    _selectedAccountId =
        widget.snapshot.primaryAccount?.id ?? widget.snapshot.accounts.first.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiAccountEnabled =
        widget.settingsController.multiAccountModeEnabled;

    return _FinanceSheetScaffold(
      icon: Icons.receipt_long_outlined,
      title: 'Add Expense',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'Amount'),
          const SizedBox(height: 10),
          _AmountField(
            controller: _amountController,
            prefix: _selectedAccount.currencyCode,
            accentColor: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 18),
          _FieldLabel(text: 'Description'),
          const SizedBox(height: 10),
          TextField(
            controller: _descriptionController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What was this expense for?',
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel(text: 'Category'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final category in _categories)
                _CategoryOptionChip(
                  category: category,
                  selected: _selectedCategoryId == category.id,
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = category.id;
                    });
                  },
                ),
            ],
          ),
          if (multiAccountEnabled) ...[
            const SizedBox(height: 18),
            _FieldLabel(text: 'Account'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final account in widget.snapshot.accounts)
                  _AccountOptionChip(
                    account: account,
                    selected: _selectedAccountId == account.id,
                    onTap: () {
                      setState(() {
                        _selectedAccountId = account.id;
                      });
                    },
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.mode_comment_outlined,
                size: 18,
                color: AppColors.muted.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'Add a comment',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Add Expense'),
            ),
          ),
        ],
      ),
    );
  }

  FinanceAccount get _selectedAccount =>
      widget.snapshot.findAccount(_selectedAccountId) ??
      widget.snapshot.primaryAccount ??
      widget.snapshot.accounts.first;

  Future<void> _submit() async {
    final title = _descriptionController.text.trim();
    final amount = _parseAmount(_amountController.text);

    if (title.isEmpty || amount == null || amount <= 0) {
      _showError('Enter a description and a valid amount.');
      return;
    }

    final success = await widget.controller.addTransaction(
      title: title,
      amount: amount,
      type: TransactionType.expense,
      accountId: _selectedAccountId,
      categoryId: _selectedCategoryId,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(widget.controller.errorMessage ?? 'Unable to add expense.');
      return;
    }

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TransferComposerSheet extends StatefulWidget {
  const _TransferComposerSheet({
    required this.controller,
    required this.snapshot,
  });

  final FinanceController controller;
  final FinanceSnapshot snapshot;

  @override
  State<_TransferComposerSheet> createState() => _TransferComposerSheetState();
}

class _TransferComposerSheetState extends State<_TransferComposerSheet> {
  late final TextEditingController _amountController;
  late String _fromAccountId;
  late String _toAccountId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _fromAccountId = widget.snapshot.accounts.first.id;
    _toAccountId = widget.snapshot.accounts
        .firstWhere(
          (account) => account.id != _fromAccountId,
          orElse: () => widget.snapshot.accounts.first,
        )
        .id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasEnoughAccounts = widget.snapshot.accounts.length > 1;

    return _FinanceSheetScaffold(
      icon: Icons.compare_arrows_rounded,
      title: 'Transfer Funds',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(text: 'From Account'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _fromAccountId,
            items: widget.snapshot.accounts
                .map(
                  (account) => DropdownMenuItem<String>(
                    value: account.id,
                    child: Text(_accountSummary(account)),
                  ),
                )
                .toList(),
            onChanged: hasEnoughAccounts
                ? (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _fromAccountId = value;
                      if (_fromAccountId == _toAccountId) {
                        _toAccountId = _firstOtherAccountId(_fromAccountId);
                      }
                    });
                  }
                : null,
          ),
          const SizedBox(height: 18),
          _FieldLabel(text: 'To Account'),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: hasEnoughAccounts ? _toAccountId : null,
            items: widget.snapshot.accounts
                .where((account) => account.id != _fromAccountId)
                .map(
                  (account) => DropdownMenuItem<String>(
                    value: account.id,
                    child: Text(_accountSummary(account)),
                  ),
                )
                .toList(),
            onChanged: hasEnoughAccounts
                ? (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _toAccountId = value;
                    });
                  }
                : null,
          ),
          const SizedBox(height: 18),
          _FieldLabel(text: 'Amount'),
          const SizedBox(height: 10),
          _AmountField(
            controller: _amountController,
            prefix: _fromAccount.currencyCode,
            accentColor: AppColors.income,
          ),
          if (!hasEnoughAccounts) ...[
            const SizedBox(height: 14),
            Text(
              'Add at least two accounts before using transfers.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: hasEnoughAccounts ? _submit : null,
              child: const Text('Confirm Transfer'),
            ),
          ),
        ],
      ),
    );
  }

  FinanceAccount get _fromAccount =>
      widget.snapshot.findAccount(_fromAccountId) ??
      widget.snapshot.accounts.first;

  String _firstOtherAccountId(String currentId) {
    return widget.snapshot.accounts
        .firstWhere(
          (account) => account.id != currentId,
          orElse: () => widget.snapshot.accounts.first,
        )
        .id;
  }

  String _accountSummary(FinanceAccount account) {
    return '${account.name} (${AppFormatters.groupedNumber(account.balance)} ${account.currencyCode})';
  }

  Future<void> _submit() async {
    final amount = _parseAmount(_amountController.text);

    if (amount == null || amount <= 0) {
      _showError('Enter a valid amount to transfer.');
      return;
    }

    if (_fromAccountId == _toAccountId) {
      _showError('Choose different accounts for the transfer.');
      return;
    }

    final success = await widget.controller.transferBetweenAccounts(
      fromAccountId: _fromAccountId,
      toAccountId: _toAccountId,
      amount: amount,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showError(widget.controller.errorMessage ?? 'Unable to transfer funds.');
      return;
    }

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _FinanceSheetScaffold extends StatelessWidget {
  const _FinanceSheetScaffold({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final maxHeight = MediaQuery.of(context).size.height * 0.86;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(icon, size: 18, color: palette.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF4F6FA),
                          foregroundColor: AppColors.ink,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: const Color(0xFF55657D),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.controller,
    required this.prefix,
    required this.accentColor,
  });

  final TextEditingController controller;
  final String prefix;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return TextField(
      controller: controller,
      inputFormatters: const [GroupedAmountInputFormatter()],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: textTheme.headlineMedium?.copyWith(
        fontSize: 20,
        color: const Color(0xFF697892),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: '0.00',
        fillColor: const Color(0xFFF4F7FB),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 10, 0),
          child: Center(
            widthFactor: 1,
            child: Text(
              prefix,
              style: textTheme.titleLarge?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryOptionChip extends StatelessWidget {
  const _CategoryOptionChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FinanceCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _OptionChip(
      selected: selected,
      onTap: onTap,
      leading: Text(category.emoji, style: const TextStyle(fontSize: 14)),
      label: category.name,
    );
  }
}

class _AccountOptionChip extends StatelessWidget {
  const _AccountOptionChip({
    required this.account,
    required this.selected,
    required this.onTap,
  });

  final FinanceAccount account;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return _OptionChip(
      selected: selected,
      onTap: onTap,
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: palette.primary,
          shape: BoxShape.circle,
        ),
      ),
      label: account.name,
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.label,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFFAF3) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? palette.primary : AppColors.outline,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              leading,
              const SizedBox(width: 8),
              Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<FinanceCategory> _buildCategorySelection(
  FinanceSnapshot snapshot, {
  required CategoryKind kind,
}) {
  final filtered = snapshot.categoriesOfKind(kind);
  return filtered.isEmpty ? snapshot.categories : filtered;
}

double? _parseAmount(String rawValue) {
  return GroupedAmountInputFormatter.parse(rawValue);
}
