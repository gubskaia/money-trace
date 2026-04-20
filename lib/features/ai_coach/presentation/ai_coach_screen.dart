import 'package:flutter/material.dart';
import 'package:money_trace/core/widgets/app_card.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/presentation/widgets/advice_card.dart';

class AiCoachScreen extends StatelessWidget {
  const AiCoachScreen({super.key, required this.controller});

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

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            Text('AI Coach', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'This area currently uses a rule-based coach, but the structure is already ready for a real LLM-backed assistant.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How the real AI layer will plug in',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  const _StepLabel(
                    index: '01',
                    text:
                        'Aggregate account balances, inflow, spending categories, and behavior patterns.',
                  ),
                  const SizedBox(height: 10),
                  const _StepLabel(
                    index: '02',
                    text:
                        'Build a safe prompt without exposing unnecessary personal details.',
                  ),
                  const SizedBox(height: 10),
                  const _StepLabel(
                    index: '03',
                    text:
                        'Generate suggestions from the LLM and normalize them into app-friendly cards.',
                  ),
                  const SizedBox(height: 10),
                  const _StepLabel(
                    index: '04',
                    text:
                        'Display the suggestions in the UI and connect them back to real in-app metrics.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Current suggestions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ...controller.advice.map(
              (advice) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AdviceCard(advice: advice),
              ),
            ),
            const SizedBox(height: 6),
            AppCard(
              child: Text(
                'When we switch to the real AI integration, this screen can also include conversation history, budgeting scenarios, and more personal recommendations based on long-term behavior.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StepLabel extends StatelessWidget {
  const _StepLabel({required this.index, required this.text});

  final String index;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(index, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    );
  }
}
