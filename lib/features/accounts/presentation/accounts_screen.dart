import 'package:flutter/material.dart';
import 'package:money_trace/core/widgets/app_card.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/presentation/widgets/account_composer_dialog.dart';
import 'package:money_trace/utils/formatters.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key, required this.controller});

  final FinanceController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final snapshot = controller.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final totalBalanceCurrencyCode = snapshot.reportingCurrencyCode;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text('Accounts', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'The architecture already supports multiple accounts, separate balances, and future transfers between them.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total balance',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppFormatters.money(
                            snapshot.totalBalance,
                            currencyCode: totalBalanceCurrencyCode,
                          ),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      AccountComposerDialog.show(
                        context,
                        controller: controller,
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add account'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...snapshot.accounts.map(
              (account) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_iconFor(account.kind)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  account.kind.label,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.money(
                              account.balance,
                              currencyCode: account.currencyCode,
                            ),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _iconFor(AccountKind kind) {
    switch (kind) {
      case AccountKind.cash:
        return Icons.payments_outlined;
      case AccountKind.card:
        return Icons.credit_card_rounded;
      case AccountKind.savings:
        return Icons.savings_outlined;
      case AccountKind.investment:
        return Icons.show_chart_rounded;
    }
  }

}
