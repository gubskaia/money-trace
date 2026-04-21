import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/features/auth/application/auth_controller.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_advice.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/features/finance/presentation/widgets/account_editor_sheet.dart';
import 'package:money_trace/features/finance/presentation/widgets/account_visuals.dart';
import 'package:money_trace/features/finance/presentation/widgets/transaction_composer_sheet.dart';
import 'package:money_trace/utils/formatters.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({
    super.key,
    required this.authController,
    required this.controller,
    required this.settingsController,
  });

  final AuthController authController;
  final FinanceController controller;
  final AppSettingsController settingsController;

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  late final PageController _pageController;
  int _currentCardIndex = 0;
  bool _isActionMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.955);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.authController,
        widget.controller,
        widget.settingsController,
      ]),
      builder: (context, child) {
        final snapshot = widget.controller.snapshot;

        if (widget.controller.isLoading && snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot == null) {
          return _ErrorState(
            message:
                widget.controller.errorMessage ??
                'Unable to load finance data.',
            onRetry: widget.controller.load,
          );
        }

        final advice = widget.controller.advice.isEmpty
            ? null
            : widget.controller.advice.first;

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WelcomeHeader(
                      initials: widget.authController.initials,
                      displayName: widget.authController.displayName,
                      onSettingsTap: () => context.push('/settings'),
                    ),
                    const SizedBox(height: 14),
                    _AccountsCarousel(
                      snapshot: snapshot,
                      multiAccountModeEnabled:
                          widget.settingsController.multiAccountModeEnabled,
                      pageController: _pageController,
                      onPageChanged: (index) {
                        if (_currentCardIndex == index) {
                          return;
                        }
                        setState(() {
                          _currentCardIndex = index;
                        });
                      },
                      onNextTap: () =>
                          _animateToNextCard(snapshot.accounts.length + 1),
                      onEditTap: (account) {
                        AccountEditorSheet.show(
                          context,
                          controller: widget.controller,
                          account: account,
                          onOpenSettings: () => context.push('/settings'),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (advice != null) ...[
                      _InsightCard(advice: advice),
                      const SizedBox(height: 20),
                    ],
                    _SectionHeader(
                      title: 'Recent Activity',
                      actionLabel: 'See all',
                      onTap: () => context.push('/activity'),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RefreshIndicator(
                        color: Theme.of(context).colorScheme.primary,
                        onRefresh: widget.controller.load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 132),
                          itemCount: snapshot.recentTransactions.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final transaction =
                                snapshot.recentTransactions[index];

                            return _ActivityTile(
                              transaction: transaction,
                              category: snapshot.findCategory(
                                transaction.categoryId,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isActionMenuOpen)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeActionMenu,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              right: 18,
              bottom: 18,
              child: _QuickActionMenu(
                isOpen: _isActionMenuOpen,
                showTransfer: widget.settingsController.multiAccountModeEnabled,
                onPrimaryTap: _toggleActionMenu,
                onIncomeTap: () => _openIncomeSheet(snapshot),
                onExpenseTap: () => _openExpenseSheet(snapshot),
                onTransferTap: () => _openTransferSheet(snapshot),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _animateToNextCard(int cardCount) async {
    if (!_pageController.hasClients || cardCount <= 1) {
      return;
    }

    final nextIndex = (_currentCardIndex + 1) % cardCount;
    await _pageController.animateToPage(
      nextIndex,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _toggleActionMenu() {
    setState(() {
      _isActionMenuOpen = !_isActionMenuOpen;
    });
  }

  void _closeActionMenu() {
    if (!_isActionMenuOpen) {
      return;
    }

    setState(() {
      _isActionMenuOpen = false;
    });
  }

  Future<void> _openIncomeSheet(FinanceSnapshot snapshot) async {
    _closeActionMenu();
    await TransactionComposerSheet.showIncome(
      context,
      controller: widget.controller,
      settingsController: widget.settingsController,
      snapshot: snapshot,
    );
  }

  Future<void> _openExpenseSheet(FinanceSnapshot snapshot) async {
    _closeActionMenu();
    await TransactionComposerSheet.showExpense(
      context,
      controller: widget.controller,
      settingsController: widget.settingsController,
      snapshot: snapshot,
    );
  }

  Future<void> _openTransferSheet(FinanceSnapshot snapshot) async {
    if (!widget.settingsController.multiAccountModeEnabled) {
      return;
    }

    _closeActionMenu();
    await TransactionComposerSheet.showTransfer(
      context,
      controller: widget.controller,
      settingsController: widget.settingsController,
      snapshot: snapshot,
    );
  }
}

class _AccountsCarousel extends StatelessWidget {
  const _AccountsCarousel({
    required this.snapshot,
    required this.multiAccountModeEnabled,
    required this.pageController,
    required this.onPageChanged,
    required this.onNextTap,
    required this.onEditTap,
  });

  final FinanceSnapshot snapshot;
  final bool multiAccountModeEnabled;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onNextTap;
  final ValueChanged<FinanceAccount> onEditTap;

  @override
  Widget build(BuildContext context) {
    if (!multiAccountModeEnabled) {
      final primaryAccount = snapshot.primaryAccount;

      return SizedBox(
        height: 196,
        child: primaryAccount == null
            ? _AggregateBalanceCard(snapshot: snapshot)
            : _AccountBalanceCard(
                account: primaryAccount,
                onEditTap: () => onEditTap(primaryAccount),
              ),
      );
    }

    final cardCount = snapshot.accounts.length + 1;

    return SizedBox(
      height: 196,
      child: PageView.builder(
        controller: pageController,
        padEnds: false,
        itemCount: cardCount,
        onPageChanged: onPageChanged,
        itemBuilder: (context, index) {
          final isAggregate = index == 0;
          final account = isAggregate ? null : snapshot.accounts[index - 1];

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: isAggregate
                ? _AggregateBalanceCard(
                    snapshot: snapshot,
                    onNextTap: onNextTap,
                  )
                : _AccountBalanceCard(
                    account: account!,
                    onEditTap: () => onEditTap(account),
                    onNextTap: onNextTap,
                  ),
          );
        },
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({
    required this.initials,
    required this.displayName,
    required this.onSettingsTap,
  });

  final String initials;
  final String displayName;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.appPalette;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [palette.primaryLight, palette.primaryDark],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF77869A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE4E8EF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: IconButton(
            onPressed: onSettingsTap,
            icon: const Icon(
              Icons.settings_outlined,
              color: Color(0xFF66758A),
              size: 21,
            ),
          ),
        ),
      ],
    );
  }
}

class _AggregateBalanceCard extends StatelessWidget {
  const _AggregateBalanceCard({required this.snapshot, this.onNextTap});

  final FinanceSnapshot snapshot;
  final VoidCallback? onNextTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dailyAverage = _buildDailyAverage(snapshot);
    final currencyCode = snapshot.reportingCurrencyCode;

    return _CardBase(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (onNextTap != null)
            Positioned(
              right: 14,
              top: 78,
              child: _CircularCardAction(
                onTap: onNextTap!,
                icon: Icons.chevron_right_rounded,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 64, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aggregate Balance',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      AppFormatters.groupedNumber(snapshot.totalBalance),
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        currencyCode,
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniMetric(
                            label: 'Spent this month',
                            value:
                                AppFormatters.compactMoney(
                                  -snapshot.expensesThisMonth,
                                  currencyCode: currencyCode,
                                ),
                          ),
                        ),
                        VerticalDivider(
                          width: 16,
                          thickness: 1,
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        Expanded(
                          child: _MiniMetric(
                            label: 'Daily average',
                            value: AppFormatters.compactMoney(
                              dailyAverage,
                              currencyCode: currencyCode,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _buildDailyAverage(FinanceSnapshot snapshot) {
    final now = DateTime.now();
    final expenses = snapshot.transactions.where((transaction) {
      return transaction.type == TransactionType.expense &&
          transaction.occurredAt.year == now.year &&
          transaction.occurredAt.month == now.month;
    }).toList();

    if (expenses.isEmpty) {
      return 0;
    }

    expenses.sort((left, right) => left.occurredAt.compareTo(right.occurredAt));
    final firstDay = expenses.first.occurredAt.day;
    final trackedDays = (now.day - firstDay) + 1;

    return snapshot.expensesThisMonth / (trackedDays <= 0 ? 1 : trackedDays);
  }
}

class _AccountBalanceCard extends StatelessWidget {
  const _AccountBalanceCard({
    required this.account,
    this.onEditTap,
    this.onNextTap,
  });

  final FinanceAccount account;
  final VoidCallback? onEditTap;
  final VoidCallback? onNextTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final accentColor = accountAccentColor(account.accentColorValue);

    return _CardBase(
      gradient: accountCardGradient(account.accentColorValue),
      shadowColor: accentColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (onEditTap != null)
            Positioned(
              right: 14,
              top: 18,
              child: _CircularCardAction(
                onTap: onEditTap!,
                icon: Icons.edit_outlined,
                small: true,
              ),
            ),
          if (onNextTap != null)
            Positioned(
              right: 14,
              top: 78,
              child: _CircularCardAction(
                onTap: onNextTap!,
                icon: Icons.chevron_right_rounded,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              22,
              onNextTap != null || onEditTap != null ? 72 : 20,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account.name,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Text(
                      AppFormatters.groupedNumber(account.balance),
                      style: textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        account.currencyCode,
                        style: textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardBase extends StatelessWidget {
  const _CardBase({required this.child, this.gradient, this.shadowColor});

  final Widget child;
  final LinearGradient? gradient;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final effectiveShadowColor = shadowColor ?? palette.primary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient:
            gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.gradientStart, palette.gradientEnd],
            ),
        boxShadow: [
          BoxShadow(
            color: effectiveShadowColor.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -34,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -46,
            bottom: -58,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _CircularCardAction extends StatelessWidget {
  const _CircularCardAction({
    required this.onTap,
    required this.icon,
    this.small = false,
  });

  final VoidCallback onTap;
  final IconData icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 36.0 : 40.0;
    final iconSize = small ? 18.0 : 28.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.84),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.advice});

  final FinanceAdvice advice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final badge = switch (advice.tone) {
      AdviceTone.warning => 'warning',
      AdviceTone.success => 'good',
      AdviceTone.info => 'insight',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8ECF1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A0F1A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5EEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: Color(0xFF9B59F3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'AI Insight',
                style: textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF7C3AED),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6B13D),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge,
                  style: textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            advice.title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            advice.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF68758C),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.appPalette;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            actionLabel,
            style: textTheme.bodyMedium?.copyWith(
              color: palette.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.transaction, this.category});

  final FinanceTransaction transaction;
  final FinanceCategory? category;

  @override
  Widget build(BuildContext context) {
    final amount = transaction.type == TransactionType.income
        ? transaction.amount
        : -transaction.amount;
    final amountText = AppFormatters.compactMoney(
      amount,
      currencyCode: transaction.currencyCode,
    );
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECF1)),
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
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${category?.name ?? "General"} - ${AppFormatters.isoDate(transaction.occurredAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF758399),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            amountText,
            style: textTheme.titleLarge?.copyWith(
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

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final borderRadius = BorderRadius.circular(24);
    final shape = RoundedRectangleBorder(borderRadius: borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: SizedBox(
            width: 68,
            height: 68,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final turns = Tween<double>(
                    begin: 0.82,
                    end: 1,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: RotationTransition(turns: turns, child: child),
                  );
                },
                child: Icon(
                  icon,
                  key: ValueKey(icon),
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionMenu extends StatefulWidget {
  const _QuickActionMenu({
    required this.isOpen,
    required this.showTransfer,
    required this.onPrimaryTap,
    required this.onIncomeTap,
    required this.onExpenseTap,
    required this.onTransferTap,
  });

  final bool isOpen;
  final bool showTransfer;
  final VoidCallback onPrimaryTap;
  final VoidCallback onIncomeTap;
  final VoidCallback onExpenseTap;
  final VoidCallback onTransferTap;

  @override
  State<_QuickActionMenu> createState() => _QuickActionMenuState();
}

class _QuickActionMenuState extends State<_QuickActionMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _menuReveal;
  late final Animation<double> _incomeFade;
  late final Animation<double> _expenseFade;
  late final Animation<double> _transferFade;
  late final Animation<Offset> _incomeSlide;
  late final Animation<Offset> _expenseSlide;
  late final Animation<Offset> _transferSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 180),
      value: widget.isOpen ? 1 : 0,
    );
    _menuReveal = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _transferFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.00, 0.48, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.00, 0.70, curve: Curves.easeInCubic),
    );
    _expenseFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.12, 0.66, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.00, 0.82, curve: Curves.easeInCubic),
    );
    _incomeFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.24, 0.84, curve: Curves.easeOutCubic),
      reverseCurve: const Interval(0.00, 1.00, curve: Curves.easeInCubic),
    );
    _transferSlide = Tween<Offset>(
      begin: const Offset(0.18, 0.22),
      end: Offset.zero,
    ).animate(_transferFade);
    _expenseSlide = Tween<Offset>(
      begin: const Offset(0.22, 0.18),
      end: Offset.zero,
    ).animate(_expenseFade);
    _incomeSlide = Tween<Offset>(
      begin: const Offset(0.26, 0.14),
      end: Offset.zero,
    ).animate(_incomeFade);
  }

  @override
  void didUpdateWidget(covariant _QuickActionMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isOpen == oldWidget.isOpen) {
      return;
    }

    if (widget.isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_controller.value == 0) {
              return const SizedBox.shrink();
            }

            return IgnorePointer(
              ignoring: !widget.isOpen,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.bottomRight,
                  heightFactor: _menuReveal.value,
                  child: child,
                ),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _AnimatedQuickActionMenuButton(
                fade: _incomeFade,
                slide: _incomeSlide,
                child: _QuickActionMenuButton(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Income',
                  onTap: widget.onIncomeTap,
                ),
              ),
              const SizedBox(height: 14),
              _AnimatedQuickActionMenuButton(
                fade: _expenseFade,
                slide: _expenseSlide,
                child: _QuickActionMenuButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Expense',
                  onTap: widget.onExpenseTap,
                ),
              ),
              const SizedBox(height: 14),
              _AnimatedQuickActionMenuButton(
                fade: _transferFade,
                slide: _transferSlide,
                child: widget.showTransfer
                    ? _QuickActionMenuButton(
                        icon: Icons.compare_arrows_rounded,
                        label: 'Transfer',
                        onTap: widget.onTransferTap,
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: widget.showTransfer ? 16 : 0),
            ],
          ),
        ),
        _QuickAddButton(
          onTap: widget.onPrimaryTap,
          icon: widget.isOpen ? Icons.close_rounded : Icons.add_rounded,
        ),
      ],
    );
  }
}

class _AnimatedQuickActionMenuButton extends StatelessWidget {
  const _AnimatedQuickActionMenuButton({
    required this.fade,
    required this.slide,
    required this.child,
  });

  final Animation<double> fade;
  final Animation<Offset> slide;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _QuickActionMenuButton extends StatelessWidget {
  const _QuickActionMenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final palette = context.appPalette;
    final borderRadius = BorderRadius.circular(20);
    final shape = RoundedRectangleBorder(borderRadius: borderRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.primary,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: palette.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 21, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
