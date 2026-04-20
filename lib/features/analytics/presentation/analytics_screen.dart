import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/widgets/app_card.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_transaction.dart';
import 'package:money_trace/utils/formatters.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({
    super.key,
    required this.controller,
    required this.settingsController,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _AnalyticsRange _selectedRange = _AnalyticsRange.month;
  _BreakdownMode _breakdownMode = _BreakdownMode.expenses;
  String? _selectedAccountId;

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

        final effectiveAccountId =
            widget.settingsController.multiAccountModeEnabled
            ? _selectedAccountId
            : snapshot.primaryAccount?.id;
        final bundle = _buildAnalyticsBundle(
          snapshot,
          selectedAccountId: effectiveAccountId,
        );
        final currentAccount = effectiveAccountId == null
            ? null
            : snapshot.findAccount(effectiveAccountId);
        final currencyCode =
            currentAccount?.currencyCode ??
            (snapshot.accounts.isEmpty
                ? 'KZT'
                : snapshot.accounts.first.currencyCode);

        return RefreshIndicator(
          color: Theme.of(context).colorScheme.primary,
          onRefresh: widget.controller.load,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF9FBFC), Color(0xFFF5F7FA)],
              ),
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Analytics',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 24,
                            ),
                      ),
                    ),
                    _RangeSelector(
                      selectedRange: _selectedRange,
                      onSelected: (range) {
                        setState(() {
                          _selectedRange = range;
                        });
                      },
                    ),
                  ],
                ),
                if (widget.settingsController.multiAccountModeEnabled) ...[
                  const SizedBox(height: 18),
                  _AccountDropdown(
                    snapshot: snapshot,
                    selectedAccountId: _selectedAccountId,
                    onChanged: (accountId) {
                      setState(() {
                        _selectedAccountId = accountId;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ] else
                  const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Income',
                        value: _moneyValue(bundle.incomeTotal, currencyCode),
                        delta: _buildDelta(
                          bundle.incomeTotal,
                          bundle.previousIncomeTotal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Total Expenses',
                        value: _moneyValue(bundle.expenseTotal, currencyCode),
                        delta: _buildDelta(
                          bundle.expenseTotal,
                          bundle.previousExpenseTotal,
                          inverse: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: 'Daily Avg (Expenses)',
                        value: _moneyValue(
                          bundle.averageDailyExpenses,
                          currencyCode,
                        ),
                        footer:
                            '${bundle.period.daysCount} ${bundle.period.daysCount == 1 ? "day" : "days"}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: 'Net Flow',
                        value: _moneyValue(bundle.netFlow, currencyCode),
                        valueColor: bundle.netFlow >= 0
                            ? AppColors.income
                            : AppColors.expense,
                        footer: 'Income - Expenses',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ChartCard(
                  title: 'Cash Flow Trend',
                  labels: bundle.xAxisLabels,
                  primaryValues: bundle.cashFlowSeries,
                  primaryColor: AppColors.expense,
                  axisLabels: _buildAxisLabels(bundle.cashFlowExtents),
                ),
                const SizedBox(height: 18),
                _ChartCard(
                  title: 'Income vs Expenses',
                  labels: bundle.xAxisLabels,
                  primaryValues: bundle.incomeSeries,
                  secondaryValues: bundle.expenseSeries,
                  primaryColor: AppColors.income,
                  secondaryColor: AppColors.expense,
                  axisLabels: _buildAxisLabels(bundle.comparisonExtents),
                ),
                const SizedBox(height: 18),
                _CategoryBreakdownCard(
                  breakdownMode: _breakdownMode,
                  items: bundle.breakdownItems(_breakdownMode),
                  currencyCode: currencyCode,
                  onModeChanged: (mode) {
                    setState(() {
                      _breakdownMode = mode;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _AnalyticsBundle _buildAnalyticsBundle(
    FinanceSnapshot snapshot, {
    required String? selectedAccountId,
  }) {
    final period = _periodFor(_selectedRange);
    final previousPeriod = _AnalyticsPeriod(
      start: period.start.subtract(Duration(days: period.daysCount)),
      daysCount: period.daysCount,
    );

    final currentTransactions = _transactionsForPeriod(
      snapshot,
      period,
      selectedAccountId: selectedAccountId,
    );
    final previousTransactions = _transactionsForPeriod(
      snapshot,
      previousPeriod,
      selectedAccountId: selectedAccountId,
    );

    double incomeFor(List<FinanceTransaction> transactions) {
      return transactions
          .where((transaction) => transaction.type == TransactionType.income)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    }

    double expenseFor(List<FinanceTransaction> transactions) {
      return transactions
          .where((transaction) => transaction.type == TransactionType.expense)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
    }

    final incomeTotal = incomeFor(currentTransactions);
    final expenseTotal = expenseFor(currentTransactions);
    final previousIncomeTotal = incomeFor(previousTransactions);
    final previousExpenseTotal = expenseFor(previousTransactions);

    final currentDayBuckets = _dailyBuckets(currentTransactions, period);
    final xAxisLabels = _buildXAxisLabels(period);

    return _AnalyticsBundle(
      snapshot: snapshot,
      period: period,
      incomeTotal: incomeTotal,
      expenseTotal: expenseTotal,
      previousIncomeTotal: previousIncomeTotal,
      previousExpenseTotal: previousExpenseTotal,
      averageDailyExpenses:
          expenseTotal / math.max(1, period.daysCount.toDouble()),
      netFlow: incomeTotal - expenseTotal,
      cashFlowSeries: [
        for (final bucket in currentDayBuckets)
          bucket.incomeTotal - bucket.expenseTotal,
      ],
      incomeSeries: [
        for (final bucket in currentDayBuckets) bucket.incomeTotal,
      ],
      expenseSeries: [
        for (final bucket in currentDayBuckets) bucket.expenseTotal,
      ],
      xAxisLabels: xAxisLabels,
      expenseBreakdown: _buildBreakdownItems(
        snapshot,
        currentTransactions,
        TransactionType.expense,
      ),
      incomeBreakdown: _buildBreakdownItems(
        snapshot,
        currentTransactions,
        TransactionType.income,
      ),
    );
  }

  List<FinanceTransaction> _transactionsForPeriod(
    FinanceSnapshot snapshot,
    _AnalyticsPeriod period, {
    required String? selectedAccountId,
  }) {
    return snapshot.transactions.where((transaction) {
      final transactionDay = _dateOnly(transaction.occurredAt);
      final inRange =
          !transactionDay.isBefore(period.start) &&
          !transactionDay.isAfter(period.end);
      final matchesAccount =
          selectedAccountId == null ||
          transaction.accountId == selectedAccountId;
      return inRange && matchesAccount;
    }).toList();
  }

  List<_DayBucket> _dailyBuckets(
    List<FinanceTransaction> transactions,
    _AnalyticsPeriod period,
  ) {
    final buckets = [
      for (var index = 0; index < period.daysCount; index++)
        _DayBucket(date: period.start.add(Duration(days: index))),
    ];

    for (final transaction in transactions) {
      final day = _dateOnly(transaction.occurredAt);
      final dayIndex = day.difference(period.start).inDays;
      if (dayIndex < 0 || dayIndex >= buckets.length) {
        continue;
      }

      final bucket = buckets[dayIndex];
      if (transaction.type == TransactionType.income) {
        bucket.incomeTotal += transaction.amount;
      } else {
        bucket.expenseTotal += transaction.amount;
      }
    }

    return buckets;
  }

  List<_BreakdownItem> _buildBreakdownItems(
    FinanceSnapshot snapshot,
    List<FinanceTransaction> transactions,
    TransactionType type,
  ) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      if (transaction.type != type) {
        continue;
      }
      totals.update(
        transaction.categoryId,
        (current) => current + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }

    final grandTotal = totals.values.fold<double>(
      0,
      (sum, amount) => sum + amount,
    );
    final items = totals.entries.map((entry) {
      final category = snapshot.findCategory(entry.key);
      return _BreakdownItem(
        label: category?.name ?? 'General',
        emoji: category?.emoji ?? '*',
        color: category?.tone.color ?? AppColors.primary,
        amount: entry.value,
        share: grandTotal == 0 ? 0 : entry.value / grandTotal,
      );
    }).toList()..sort((left, right) => right.amount.compareTo(left.amount));

    return items;
  }

  List<String> _buildXAxisLabels(_AnalyticsPeriod period) {
    final dateFormat = DateFormat('MMM d');
    if (period.daysCount <= 6) {
      return [
        for (var index = 0; index < period.daysCount; index++)
          dateFormat.format(period.start.add(Duration(days: index))),
      ];
    }

    const labelCount = 6;
    return [
      for (var index = 0; index < labelCount; index++)
        dateFormat.format(
          period.start.add(
            Duration(
              days: ((period.daysCount - 1) * index / (labelCount - 1)).round(),
            ),
          ),
        ),
    ];
  }

  List<String> _buildAxisLabels(_ChartExtents extents) {
    final ticks = extents.ticks;
    return ticks.reversed.map(_formatAxisLabel).toList();
  }

  _MetricDelta _buildDelta(
    double current,
    double previous, {
    bool inverse = false,
  }) {
    if (previous == 0) {
      if (current == 0) {
        return const _MetricDelta(
          text: '0% vs last',
          color: AppColors.income,
          icon: Icons.trending_up_rounded,
        );
      }

      return _MetricDelta(
        text: '100% vs last',
        color: inverse ? AppColors.expense : AppColors.income,
        icon: inverse ? Icons.trending_down_rounded : Icons.trending_up_rounded,
      );
    }

    final change = ((current - previous) / previous) * 100;
    final effectiveChange = inverse ? -change : change;
    final isPositive = effectiveChange >= 0;

    return _MetricDelta(
      text: '${effectiveChange.abs().round()}% vs last',
      color: isPositive ? AppColors.income : AppColors.expense,
      icon: isPositive
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded,
    );
  }

  String _moneyValue(double value, String currencyCode) {
    final prefix = value > 0 ? '+' : '';
    return '$prefix$currencyCode ${AppFormatters.groupedNumber(value)}';
  }

  String _formatAxisLabel(double value) {
    final absolute = value.abs();
    if (absolute >= 1000) {
      return AppFormatters.compactMoney(value);
    }
    if (absolute == absolute.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  _AnalyticsPeriod _periodFor(_AnalyticsRange range) {
    final today = _dateOnly(DateTime.now());
    return switch (range) {
      _AnalyticsRange.week => _AnalyticsPeriod(
        start: today.subtract(const Duration(days: 6)),
        daysCount: 7,
      ),
      _AnalyticsRange.month => _AnalyticsPeriod(
        start: today.subtract(const Duration(days: 29)),
        daysCount: 30,
      ),
      _AnalyticsRange.year => _AnalyticsPeriod(
        start: today.subtract(const Duration(days: 364)),
        daysCount: 365,
      ),
    };
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selectedRange, required this.onSelected});

  final _AnalyticsRange selectedRange;
  final ValueChanged<_AnalyticsRange> onSelected;

  @override
  Widget build(BuildContext context) {
    final controlSurface = _analyticsControlSurface(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: controlSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final range in _AnalyticsRange.values) ...[
            _RangeChip(
              label: range.label,
              selected: selectedRange == range,
              onTap: () => onSelected(range),
            ),
            if (range != _AnalyticsRange.values.last) const SizedBox(width: 2),
          ],
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardSurface = _analyticsCardSurface(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cardSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x120A0F1A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected
                  ? const Color(0xFF17243C)
                  : const Color(0xFF67768C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountDropdown extends StatelessWidget {
  const _AccountDropdown({
    required this.snapshot,
    required this.selectedAccountId,
    required this.onChanged,
  });

  final FinanceSnapshot snapshot;
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedAccountId ?? '__all__',
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        fillColor: _analyticsCardSurface(context),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: '__all__',
          child: Text('All Accounts'),
        ),
        ...snapshot.accounts.map(
          (account) => DropdownMenuItem<String>(
            value: account.id,
            child: Text(account.name),
          ),
        ),
      ],
      onChanged: (value) {
        onChanged(value == null || value == '__all__' ? null : value);
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    this.valueColor,
    this.delta,
    this.footer,
  });

  final String title;
  final String value;
  final Color? valueColor;
  final _MetricDelta? delta;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: _analyticsCardSurface(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF637797)),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: valueColor ?? const Color(0xFF14213D),
            ),
          ),
          const SizedBox(height: 12),
          if (delta != null)
            Row(
              children: [
                Icon(delta!.icon, size: 16, color: delta!.color),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    delta!.text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: delta!.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else if (footer != null)
            Text(
              footer!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF637797)),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.labels,
    required this.primaryValues,
    required this.primaryColor,
    required this.axisLabels,
    this.secondaryValues,
    this.secondaryColor,
  });

  final String title;
  final List<String> labels;
  final List<double> primaryValues;
  final Color primaryColor;
  final List<String> axisLabels;
  final List<double>? secondaryValues;
  final Color? secondaryColor;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: _analyticsCardSurface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: axisLabels
                        .map(
                          (label) => Text(
                            label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: const Color(0xFF6B7D98)),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomPaint(
                    painter: _SeriesChartPainter(
                      primaryValues: primaryValues,
                      primaryColor: primaryColor,
                      secondaryValues: secondaryValues,
                      secondaryColor: secondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels
                  .map(
                    (label) => Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: const Color(0xFF6B7D98)),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({
    required this.breakdownMode,
    required this.items,
    required this.currencyCode,
    required this.onModeChanged,
  });

  final _BreakdownMode breakdownMode;
  final List<_BreakdownItem> items;
  final String currencyCode;
  final ValueChanged<_BreakdownMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final controlSurface = _analyticsControlSurface(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Category Breakdown',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: controlSurface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ModeChip(
                    label: 'Expenses',
                    selected: breakdownMode == _BreakdownMode.expenses,
                    onTap: () => onModeChanged(_BreakdownMode.expenses),
                  ),
                  const SizedBox(width: 2),
                  _ModeChip(
                    label: 'Income',
                    selected: breakdownMode == _BreakdownMode.income,
                    onTap: () => onModeChanged(_BreakdownMode.income),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          color: _analyticsCardSurface(context),
          child: items.isEmpty
              ? SizedBox(
                  height: 84,
                  child: Center(
                    child: Text(
                      breakdownMode == _BreakdownMode.expenses
                          ? 'No expenses found for this period.'
                          : 'No income found for this period.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6C7D98),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (var index = 0; index < items.length; index++) ...[
                      _BreakdownRow(
                        item: items[index],
                        currencyCode: currencyCode,
                      ),
                      if (index != items.length - 1) const SizedBox(height: 14),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardSurface = _analyticsCardSurface(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cardSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: Color(0x120A0F1A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: selected
                  ? const Color(0xFF17243C)
                  : const Color(0xFF67768C),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.item, required this.currencyCode});

  final _BreakdownItem item;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(item.emoji, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$currencyCode ${AppFormatters.groupedNumber(item.amount)}',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: item.share.clamp(0, 1),
            backgroundColor: const Color(0xFFE7EDF4),
            minHeight: 8,
            valueColor: AlwaysStoppedAnimation<Color>(item.color),
          ),
        ),
      ],
    );
  }
}

class _SeriesChartPainter extends CustomPainter {
  _SeriesChartPainter({
    required this.primaryValues,
    required this.primaryColor,
    this.secondaryValues,
    this.secondaryColor,
  });

  final List<double> primaryValues;
  final Color primaryColor;
  final List<double>? secondaryValues;
  final Color? secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (primaryValues.isEmpty) {
      return;
    }

    final allValues = [...primaryValues, ...?secondaryValues, 0];
    var minValue = allValues.reduce(math.min).toDouble();
    var maxValue = allValues.reduce(math.max).toDouble();
    if (minValue == maxValue) {
      maxValue += 1;
      minValue -= 1;
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFD8E0EA)
      ..strokeWidth = 1;

    const gridCount = 4;
    for (var index = 0; index <= gridCount; index++) {
      final y = size.height * (index / gridCount);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawSeries(canvas, size, primaryValues, minValue, maxValue, primaryColor);

    if (secondaryValues != null && secondaryValues!.isNotEmpty) {
      _drawSeries(
        canvas,
        size,
        secondaryValues!,
        minValue,
        maxValue,
        secondaryColor ?? AppColors.info,
      );
    }
  }

  void _drawSeries(
    Canvas canvas,
    Size size,
    List<double> values,
    double minValue,
    double maxValue,
    Color color,
  ) {
    if (values.length < 2) {
      return;
    }

    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = size.width * (index / (values.length - 1));
      final normalized = (values[index] - minValue) / (maxValue - minValue);
      final y = size.height - (normalized * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.8;

    canvas.drawPath(path, paint);

    final lastNormalized = (values.last - minValue) / (maxValue - minValue);
    final lastPoint = Offset(
      size.width,
      size.height - (lastNormalized * size.height),
    );
    canvas.drawCircle(lastPoint, 3.2, Paint()..color = color);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final totalWidth = end.dx - start.dx;
    var current = 0.0;

    while (current < totalWidth) {
      final dashEnd = math.min(current + dashWidth, totalWidth);
      canvas.drawLine(
        Offset(start.dx + current, start.dy),
        Offset(start.dx + dashEnd, start.dy),
        paint,
      );
      current += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _SeriesChartPainter oldDelegate) {
    return oldDelegate.primaryValues != primaryValues ||
        oldDelegate.secondaryValues != secondaryValues ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}

class _AnalyticsBundle {
  const _AnalyticsBundle({
    required this.snapshot,
    required this.period,
    required this.incomeTotal,
    required this.expenseTotal,
    required this.previousIncomeTotal,
    required this.previousExpenseTotal,
    required this.averageDailyExpenses,
    required this.netFlow,
    required this.cashFlowSeries,
    required this.incomeSeries,
    required this.expenseSeries,
    required this.xAxisLabels,
    required this.expenseBreakdown,
    required this.incomeBreakdown,
  });

  final FinanceSnapshot snapshot;
  final _AnalyticsPeriod period;
  final double incomeTotal;
  final double expenseTotal;
  final double previousIncomeTotal;
  final double previousExpenseTotal;
  final double averageDailyExpenses;
  final double netFlow;
  final List<double> cashFlowSeries;
  final List<double> incomeSeries;
  final List<double> expenseSeries;
  final List<String> xAxisLabels;
  final List<_BreakdownItem> expenseBreakdown;
  final List<_BreakdownItem> incomeBreakdown;

  _ChartExtents get cashFlowExtents => _ChartExtents(cashFlowSeries);

  _ChartExtents get comparisonExtents =>
      _ChartExtents([...incomeSeries, ...expenseSeries]);

  List<_BreakdownItem> breakdownItems(_BreakdownMode mode) {
    return mode == _BreakdownMode.expenses ? expenseBreakdown : incomeBreakdown;
  }
}

class _AnalyticsPeriod {
  const _AnalyticsPeriod({required this.start, required this.daysCount});

  final DateTime start;
  final int daysCount;

  DateTime get end => start.add(Duration(days: daysCount - 1));
}

class _DayBucket {
  _DayBucket({required this.date});

  final DateTime date;
  double incomeTotal = 0;
  double expenseTotal = 0;
}

class _MetricDelta {
  const _MetricDelta({
    required this.text,
    required this.color,
    required this.icon,
  });

  final String text;
  final Color color;
  final IconData icon;
}

class _BreakdownItem {
  const _BreakdownItem({
    required this.label,
    required this.emoji,
    required this.color,
    required this.amount,
    required this.share,
  });

  final String label;
  final String emoji;
  final Color color;
  final double amount;
  final double share;
}

class _ChartExtents {
  _ChartExtents(List<double> values) : values = List<double>.from(values);

  final List<double> values;

  List<double> get ticks {
    final allValues = [...values, 0];
    var minValue = allValues.reduce(math.min).toDouble();
    var maxValue = allValues.reduce(math.max).toDouble();

    if (minValue == maxValue) {
      maxValue += 1;
      minValue -= 1;
    }

    const tickCount = 4;
    return [
      for (var index = 0; index <= tickCount; index++)
        minValue + ((maxValue - minValue) * index / tickCount),
    ];
  }
}

enum _AnalyticsRange { week, month, year }

enum _BreakdownMode { expenses, income }

extension on _AnalyticsRange {
  String get label {
    switch (this) {
      case _AnalyticsRange.week:
        return 'Week';
      case _AnalyticsRange.month:
        return 'Month';
      case _AnalyticsRange.year:
        return 'Year';
    }
  }
}

Color _analyticsCardSurface(BuildContext context) {
  return Colors.white;
}

Color _analyticsControlSurface(BuildContext context) {
  return const Color(0xFFF2F5FA);
}
