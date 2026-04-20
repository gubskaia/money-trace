import 'package:flutter/material.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';

class AccountComposerDialog extends StatefulWidget {
  const AccountComposerDialog({super.key, required this.controller});

  final FinanceController controller;

  static Future<void> show(
    BuildContext context, {
    required FinanceController controller,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AccountComposerDialog(controller: controller),
    );
  }

  @override
  State<AccountComposerDialog> createState() => _AccountComposerDialogState();
}

class _AccountComposerDialogState extends State<AccountComposerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _balanceController;
  AccountKind _selectedKind = AccountKind.card;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _balanceController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: const Text('New account'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account name',
                hintText: 'For example, Kaspi Gold',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balanceController,
              decoration: const InputDecoration(
                labelText: 'Opening balance',
                hintText: 'For example, 150000',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<AccountKind>(
              value: _selectedKind,
              decoration: const InputDecoration(labelText: 'Account type'),
              items: AccountKind.values
                  .map(
                    (kind) => DropdownMenuItem<AccountKind>(
                      value: kind,
                      child: Text(kind.label),
                    ),
                  )
                  .toList(),
              onChanged: (kind) {
                if (kind == null) {
                  return;
                }
                setState(() {
                  _selectedKind = kind;
                });
              },
            ),
            const SizedBox(height: 14),
            Text(
              'All demo accounts currently start in KZT. Later we can add a currency picker and transfers between accounts.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Create')),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final balance = _parseAmount(_balanceController.text);

    if (name.isEmpty || balance == null) {
      _showSnackBar('Enter an account name and a valid opening balance.');
      return;
    }

    final success = await widget.controller.addAccount(
      name: name,
      openingBalance: balance,
      kind: _selectedKind,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showSnackBar(
        widget.controller.errorMessage ?? 'Unable to create account.',
      );
      return;
    }

    Navigator.of(context).pop();
  }

  double? _parseAmount(String rawValue) {
    return double.tryParse(rawValue.replaceAll(' ', '').replaceAll(',', '.'));
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
