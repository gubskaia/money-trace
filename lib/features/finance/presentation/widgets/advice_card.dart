import 'package:flutter/material.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/widgets/app_card.dart';
import 'package:money_trace/features/finance/domain/models/finance_advice.dart';

class AdviceCard extends StatelessWidget {
  const AdviceCard({super.key, required this.advice});

  final FinanceAdvice advice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: advice.tone.softColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForTone(advice.tone), color: advice.tone.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  advice.message,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForTone(AdviceTone tone) {
    switch (tone) {
      case AdviceTone.info:
        return Icons.auto_awesome;
      case AdviceTone.success:
        return Icons.trending_up_rounded;
      case AdviceTone.warning:
        return Icons.priority_high_rounded;
    }
  }
}
