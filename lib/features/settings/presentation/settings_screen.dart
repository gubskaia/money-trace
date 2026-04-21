import 'package:flutter/material.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/core/theme/app_theme_preset.dart';
import 'package:money_trace/core/widgets/app_card.dart';
import 'package:money_trace/features/auth/application/auth_controller.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_account.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/presentation/widgets/account_editor_sheet.dart';
import 'package:money_trace/features/finance/presentation/widgets/account_composer_dialog.dart';
import 'package:money_trace/features/finance/presentation/widgets/account_visuals.dart';
import 'package:money_trace/utils/formatters.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.controller,
    required this.settingsController,
    required this.authController,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([controller, settingsController, authController]),
      builder: (context, child) {
        final snapshot = controller.snapshot;
        if (snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final expenseCategories = snapshot.categoriesOfKind(
          CategoryKind.expense,
        );
        final incomeCategories = snapshot.categoriesOfKind(CategoryKind.income);
        final multiAccountEnabled = settingsController.multiAccountModeEnabled;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF9FBFC), Color(0xFFF5F7FA)],
            ),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _ThemePreviewCard(
                preset: settingsController.themePreset,
                multiAccountEnabled: multiAccountEnabled,
              ),
              const SizedBox(height: 18),
              const _SettingsSectionTitle(
                title: 'App Theme',
                subtitle: 'Pick the accent palette for the whole app',
              ),
              const SizedBox(height: 12),
              _ThemePresetGrid(
                selectedPreset: settingsController.themePreset,
                onSelected: settingsController.updateThemePreset,
              ),
              const SizedBox(height: 18),
              _SettingsActionTile(
                icon: Icons.sell_outlined,
                iconColor: AppColors.expense,
                title: 'Expense Categories',
                subtitle:
                    '${expenseCategories.length} categories · tap to edit',
                previews: expenseCategories,
                onTap: () => _CategoryManagerSheet.show(
                  context,
                  controller: controller,
                  kind: CategoryKind.expense,
                ),
              ),
              const SizedBox(height: 14),
              _SettingsActionTile(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.income,
                title: 'Income Categories',
                subtitle: '${incomeCategories.length} categories · tap to edit',
                previews: incomeCategories,
                onTap: () => _CategoryManagerSheet.show(
                  context,
                  controller: controller,
                  kind: CategoryKind.income,
                ),
              ),
              const SizedBox(height: 14),
              _SwitchSettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: context.appPalette.primary,
                title: 'Multi-Account Mode',
                subtitle: multiAccountEnabled
                    ? 'Separate balances, account selection, and transfers enabled'
                    : 'All income and expenses use the primary account only',
                value: multiAccountEnabled,
                onChanged: settingsController.setMultiAccountMode,
              ),
              const SizedBox(height: 14),
              _SettingsActionTile(
                icon: Icons.wallet_outlined,
                iconColor: context.appPalette.primary,
                title: 'Manage Accounts',
                subtitle: multiAccountEnabled
                    ? 'Add or remove extra accounts'
                    : 'Enable multi-account mode to manage extra accounts',
                previews: snapshot.accounts
                    .map(
                      (account) => FinanceCategory(
                        id: account.id,
                        name: account.name,
                        emoji: _accountEmoji(account.kind),
                        tone: CategoryTone.sky,
                        kind: CategoryKind.expense,
                      ),
                    )
                    .toList(),
                enabled: multiAccountEnabled,
                onTap: () {
                  if (!multiAccountEnabled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Turn on multi-account mode before managing extra accounts.',
                        ),
                      ),
                    );
                    return;
                  }

                  _AccountsManagerSheet.show(
                    context,
                    controller: controller,
                    snapshot: snapshot,
                  );
                },
              ),
              if (!multiAccountEnabled) ...[
                const SizedBox(height: 14),
                const _SingleAccountHintCard(),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    await authController.signOut();
                    controller.clearSession();
                    settingsController.clearSession();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign Out'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemePreviewCard extends StatelessWidget {
  const _ThemePreviewCard({
    required this.preset,
    required this.multiAccountEnabled,
  });

  final AppThemePreset preset;
  final bool multiAccountEnabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [preset.gradientStart, preset.gradientEnd],
        ),
        boxShadow: [
          BoxShadow(
            color: preset.primary.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.palette_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current look',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${preset.label} theme',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  multiAccountEnabled
                      ? 'Multi-account mode is active'
                      : 'Single-account mode is active',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePresetGrid extends StatelessWidget {
  const _ThemePresetGrid({
    required this.selectedPreset,
    required this.onSelected,
  });

  final AppThemePreset selectedPreset;
  final ValueChanged<AppThemePreset> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: AppThemePreset.values.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 118,
      ),
      itemBuilder: (context, index) {
        final preset = AppThemePreset.values[index];
        final selected = preset == selectedPreset;

        return _ThemePresetCard(
          preset: preset,
          selected: selected,
          onTap: () => onSelected(preset),
        );
      },
    );
  }
}

class _ThemePresetCard extends StatelessWidget {
  const _ThemePresetCard({
    required this.preset,
    required this.selected,
    required this.onTap,
  });

  final AppThemePreset preset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? preset.primary : const Color(0xFFDCE3EB),
              width: selected ? 1.4 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0A0F1A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [preset.gradientStart, preset.gradientEnd],
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.24),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  preset.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.previews,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final List<FinanceCategory> previews;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.68,
      child: AppCard(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(28),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _PreviewEmojiStrip(categories: previews),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF7B8AA1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewEmojiStrip extends StatelessWidget {
  const _PreviewEmojiStrip({required this.categories});

  final List<FinanceCategory> categories;

  @override
  Widget build(BuildContext context) {
    final previewItems = categories.take(3).toList();
    final hiddenCount = categories.length - previewItems.length;

    return SizedBox(
      width: 78,
      height: 28,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < previewItems.length; index++)
            Positioned(
              left: index * 18,
              child: _PreviewEmojiBubble(label: previewItems[index].emoji),
            ),
          if (hiddenCount > 0)
            Positioned(
              left: previewItems.length * 18,
              child: _PreviewEmojiBubble(label: '+$hiddenCount'),
            ),
        ],
      ),
    );
  }
}

class _PreviewEmojiBubble extends StatelessWidget {
  const _PreviewEmojiBubble({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.8),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF61728E),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SwitchSettingsTile extends StatelessWidget {
  const _SwitchSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SingleAccountHintCard extends StatelessWidget {
  const _SingleAccountHintCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: context.appPalette.primary.withValues(alpha: 0.06),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: context.appPalette.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Single-account mode keeps the experience simple: income, expenses, recurring templates, and analytics use the main account, and transfer actions stay hidden.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF51637E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryManagerSheet extends StatelessWidget {
  const _CategoryManagerSheet({required this.controller, required this.kind});

  final FinanceController controller;
  final CategoryKind kind;

  static Future<void> show(
    BuildContext context, {
    required FinanceController controller,
    required CategoryKind kind,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CategoryManagerSheet(controller: controller, kind: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.84;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final snapshot = controller.snapshot;
        final categories = snapshot?.categoriesOfKind(kind) ?? const [];

        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: maxHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: kind == CategoryKind.expense
                                ? AppColors.expense.withValues(alpha: 0.10)
                                : AppColors.income.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            kind == CategoryKind.expense
                                ? Icons.sell_outlined
                                : Icons.account_balance_wallet_outlined,
                            color: kind == CategoryKind.expense
                                ? AppColors.expense
                                : AppColors.income,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${kind.label} Categories',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF4F6FA),
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _showCategoryEditor(context, kind: kind),
                      icon: const Icon(Icons.add_rounded),
                      label: Text('Add ${kind.label} Category'),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: categories.isEmpty
                          ? Center(
                              child: Text(
                                'No categories yet.',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            )
                          : ListView.separated(
                              itemCount: categories.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final category = categories[index];

                                return AppCard(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: category.tone.softColor,
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          category.emoji,
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          category.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      _SheetIconButton(
                                        icon: Icons.edit_outlined,
                                        onTap: () => _showCategoryEditor(
                                          context,
                                          kind: kind,
                                          existingCategory: category,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _SheetIconButton(
                                        icon: Icons.delete_outline_rounded,
                                        destructive: true,
                                        onTap: () => _deleteCategory(
                                          context,
                                          category: category,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCategoryEditor(
    BuildContext context, {
    required CategoryKind kind,
    FinanceCategory? existingCategory,
  }) async {
    final draft = await _CategoryEditorDialog.show(
      context,
      existingCategory: existingCategory,
      kind: kind,
    );

    if (draft == null) {
      return;
    }

    final success = existingCategory == null
        ? await controller.addManagedCategory(
            name: draft.name,
            kind: kind,
            emoji: draft.emoji.isEmpty ? '🏷️' : draft.emoji,
          )
        : await controller.updateCategory(
            id: existingCategory.id,
            name: draft.name,
            kind: kind,
            emoji: draft.emoji.isEmpty ? existingCategory.emoji : draft.emoji,
          );

    if (!context.mounted || success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          controller.errorMessage ??
              (existingCategory == null
                  ? 'Unable to add category.'
                  : 'Unable to update category.'),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context, {
    required FinanceCategory category,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete category'),
          content: Text('Delete "${category.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final success = await controller.deleteCategory(category.id);
    if (!context.mounted || success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(controller.errorMessage ?? 'Unable to delete category.'),
      ),
    );
  }
}

class _AccountsManagerSheet extends StatelessWidget {
  const _AccountsManagerSheet({
    required this.controller,
    required this.snapshot,
  });

  final FinanceController controller;
  final FinanceSnapshot snapshot;

  static Future<void> show(
    BuildContext context, {
    required FinanceController controller,
    required FinanceSnapshot snapshot,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _AccountsManagerSheet(controller: controller, snapshot: snapshot),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.82;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final liveSnapshot = controller.snapshot ?? snapshot;

        return SafeArea(
          top: false,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: maxHeight,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.appPalette.primary.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.wallet_outlined,
                            color: context.appPalette.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Manage Accounts',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF4F6FA),
                          ),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'The first account stays primary. Extra accounts can be added or removed here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => AccountComposerDialog.show(
                        context,
                        controller: controller,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Account'),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.separated(
                        itemCount: liveSnapshot.accounts.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final account = liveSnapshot.accounts[index];
                          final isPrimary = index == 0;
                          final accentColor = accountAccentColor(
                            account.accentColorValue,
                          );

                          return AppCard(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _accountEmoji(account.kind),
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              account.name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                          ),
                                          if (isPrimary) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: accentColor.withValues(
                                                  alpha: 0.14,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Primary',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium
                                                    ?.copyWith(
                                                      color: accentColor,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${account.kind.label} · ${account.currencyCode} ${AppFormatters.groupedNumber(account.balance)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isPrimary) ...[
                                  const SizedBox(width: 12),
                                  _SheetIconButton(
                                    icon: Icons.edit_outlined,
                                    onTap: () => AccountEditorSheet.show(
                                      context,
                                      controller: controller,
                                      account: account,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _SheetIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    destructive: true,
                                    onTap: () => _deleteAccount(
                                      context,
                                      account: account,
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(width: 12),
                                  _SheetIconButton(
                                    icon: Icons.edit_outlined,
                                    onTap: () => AccountEditorSheet.show(
                                      context,
                                      controller: controller,
                                      account: account,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteAccount(
    BuildContext context, {
    required FinanceAccount account,
  }) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete account'),
          content: Text('Delete "${account.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final success = await controller.deleteAccount(account.id);
    if (!context.mounted || success) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(controller.errorMessage ?? 'Unable to delete account.'),
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({required this.kind, this.existingCategory});

  final CategoryKind kind;
  final FinanceCategory? existingCategory;

  static Future<_CategoryDraft?> show(
    BuildContext context, {
    required CategoryKind kind,
    FinanceCategory? existingCategory,
  }) {
    return showDialog<_CategoryDraft>(
      context: context,
      builder: (context) =>
          _CategoryEditorDialog(kind: kind, existingCategory: existingCategory),
    );
  }

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;

  bool get _isEditing => widget.existingCategory != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingCategory?.name ?? '',
    );
    _emojiController = TextEditingController(
      text: widget.existingCategory?.emoji ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit ${widget.kind.label}' : 'New ${widget.kind.label}',
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'For example, Coffee or Bonus',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: 'Optional, for example ☕',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a category name.')));
      return;
    }

    Navigator.of(context).pop(_CategoryDraft(name: name, emoji: emoji));
  }
}

class _SheetIconButton extends StatelessWidget {
  const _SheetIconButton({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: destructive
                ? AppColors.expense.withValues(alpha: 0.08)
                : const Color(0xFFF2F5FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: destructive ? AppColors.expense : const Color(0xFF697B95),
          ),
        ),
      ),
    );
  }
}

class _CategoryDraft {
  const _CategoryDraft({required this.name, required this.emoji});

  final String name;
  final String emoji;
}

String _accountEmoji(AccountKind kind) {
  switch (kind) {
    case AccountKind.cash:
      return '💵';
    case AccountKind.card:
      return '💳';
    case AccountKind.savings:
      return '🏦';
    case AccountKind.investment:
      return '📈';
  }
}
