import 'package:flutter/material.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/presentation/widgets/account_visuals.dart';
import 'package:money_trace/utils/grouped_amount_input_formatter.dart';

abstract final class AccountEditorSheet {
  static Future<void> show(
    BuildContext context, {
    required FinanceController controller,
    required FinanceAccount account,
    VoidCallback? onOpenSettings,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (context) => _AccountEditorSheet(
        controller: controller,
        account: account,
        onOpenSettings: onOpenSettings,
      ),
    );
  }
}

class _AccountEditorSheet extends StatefulWidget {
  const _AccountEditorSheet({
    required this.controller,
    required this.account,
    this.onOpenSettings,
  });

  final FinanceController controller;
  final FinanceAccount account;
  final VoidCallback? onOpenSettings;

  @override
  State<_AccountEditorSheet> createState() => _AccountEditorSheetState();
}

class _AccountEditorSheetState extends State<_AccountEditorSheet> {
  static const _currencies = [
    'KZT',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'RUB',
    'CNY',
    'BRL',
  ];

  late final TextEditingController _balanceController;
  late final TextEditingController _nameController;
  late int _selectedAccentColorValue;
  late String _selectedCurrencyCode;

  @override
  void initState() {
    super.initState();
    _balanceController = TextEditingController(
      text: GroupedAmountInputFormatter.formatValue(widget.account.balance),
    );
    _nameController = TextEditingController(text: widget.account.name);
    _selectedAccentColorValue = widget.account.accentColorValue;
    _selectedCurrencyCode = widget.account.currencyCode;
  }

  @override
  void dispose() {
    _balanceController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final viewInsets = MediaQuery.of(context).viewInsets;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
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
                      Expanded(
                        child: Text(
                          'Edit Account',
                          style: textTheme.headlineSmall,
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
                  Center(
                    child: Text(
                      'Current Balance',
                      style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF66758C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _balanceController,
                      inputFormatters: const [GroupedAmountInputFormatter()],
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: textTheme.headlineLarge?.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B2740),
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        prefixText: '$_selectedCurrencyCode ',
                        prefixStyle: textTheme.headlineMedium?.copyWith(
                          color: palette.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _EditorLabel(text: 'Account Name'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Account name'),
                  ),
                  const SizedBox(height: 18),
                  _EditorLabel(text: 'Card Color'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final colorValue in kAccountAccentOptions)
                        _ColorOption(
                          color: accountAccentColor(colorValue),
                          selected: _selectedAccentColorValue == colorValue,
                          onTap: () {
                            setState(() {
                              _selectedAccentColorValue = colorValue;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _EditorLabel(text: 'Currency'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final currency in _currencies)
                        _CurrencyChip(
                          label: currency,
                          selected: _selectedCurrencyCode == currency,
                          onTap: () {
                            setState(() {
                              _selectedCurrencyCode = currency;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('Save Changes'),
                    ),
                  ),
                  if (widget.onOpenSettings != null) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onOpenSettings!.call();
                        },
                        child: const Text('General account settings →'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final balance = GroupedAmountInputFormatter.parse(_balanceController.text);

    if (name.isEmpty || balance == null || balance < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid account name and balance.'),
        ),
      );
      return;
    }

    final success = await widget.controller.updateAccount(
      id: widget.account.id,
      name: name,
      balance: balance,
      currencyCode: _selectedCurrencyCode,
      accentColorValue: _selectedAccentColorValue,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Unable to update account.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop();
  }
}

class _EditorLabel extends StatelessWidget {
  const _EditorLabel({required this.text});

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

class _ColorOption extends StatelessWidget {
  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  const _CurrencyChip({
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? palette.primary : const Color(0xFFF3F6FB),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected ? Colors.white : const Color(0xFF1B2740),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
