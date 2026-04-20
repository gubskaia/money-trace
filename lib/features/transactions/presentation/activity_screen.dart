import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/transactions/presentation/transactions_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({
    super.key,
    required this.controller,
    required this.settingsController,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        bottom: false,
        child: TransactionsScreen(
          controller: controller,
          settingsController: settingsController,
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.outline.withValues(alpha: 0.45)),
          ),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StandaloneNavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  onTap: () => context.go('/'),
                ),
                _StandaloneNavItem(
                  icon: Icons.autorenew_rounded,
                  label: 'Templates',
                  onTap: () => context.go('/templates'),
                ),
                _StandaloneNavItem(
                  icon: Icons.bar_chart_outlined,
                  label: 'Analytics',
                  onTap: () => context.go('/analytics'),
                ),
                _StandaloneNavItem(
                  icon: Icons.auto_awesome_outlined,
                  label: 'AI',
                  onTap: () => context.go('/coach'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StandaloneNavItem extends StatelessWidget {
  const _StandaloneNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.muted, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
