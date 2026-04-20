import 'package:flutter/material.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/core/theme/app_colors.dart';
import 'package:money_trace/core/theme/app_theme_palette.dart';
import 'package:money_trace/core/widgets/app_card.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/finance/domain/models/finance_category.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';
import 'package:money_trace/features/finance/domain/models/finance_template.dart';
import 'package:money_trace/utils/formatters.dart';

class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({
    super.key,
    required this.controller,
    required this.settingsController,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  final Map<String, bool> _expandedGroups = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.controller,
        widget.settingsController,
      ]),
      builder: (context, child) {
        final snapshot = widget.controller.snapshot;

        if (widget.controller.isLoading && snapshot == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot == null) {
          return Center(
            child: FilledButton(
              onPressed: widget.controller.load,
              child: const Text('Retry'),
            ),
          );
        }

        final groupedTemplates = _groupTemplates(snapshot.templates);
        for (final groupName in groupedTemplates.keys) {
          _expandedGroups.putIfAbsent(groupName, () => true);
        }

        final existingGroups = groupedTemplates.keys.toSet();
        _expandedGroups.removeWhere(
          (groupName, isExpanded) => !existingGroups.contains(groupName),
        );

        final currencyCode = snapshot.accounts.isEmpty
            ? 'KZT'
            : snapshot.accounts.first.currencyCode;

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
              child: RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: widget.controller.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
                  children: [
                    Text(
                      'Templates',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 18),
                    _TemplatesSummaryCard(
                      snapshot: snapshot,
                      currencyCode: currencyCode,
                    ),
                    const SizedBox(height: 18),
                    if (groupedTemplates.isEmpty)
                      const _TemplatesEmptyState()
                    else
                      ...groupedTemplates.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TemplateGroupCard(
                            groupName: entry.key,
                            templates: entry.value,
                            currencyCode: currencyCode,
                            snapshot: snapshot,
                            isExpanded: _expandedGroups[entry.key] ?? true,
                            onToggle: () {
                              setState(() {
                                _expandedGroups[entry.key] =
                                    !(_expandedGroups[entry.key] ?? true);
                              });
                            },
                            onEditTap: () {
                              _showGroupActions(
                                snapshot,
                                entry.key,
                                entry.value,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: _TemplatesFab(
                onTap: () async {
                  await _openTemplateComposer(snapshot);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<FinanceTemplate>> _groupTemplates(
    List<FinanceTemplate> templates,
  ) {
    final grouped = <String, List<FinanceTemplate>>{};

    for (final template in templates) {
      grouped.putIfAbsent(template.groupName, () => []).add(template);
    }

    return grouped;
  }

  Future<void> _openTemplateComposer(
    FinanceSnapshot snapshot, {
    String? initialGroupName,
    FinanceTemplate? initialTemplate,
  }) {
    return RecurringTemplateComposerSheet.show(
      context,
      controller: widget.controller,
      settingsController: widget.settingsController,
      snapshot: snapshot,
      initialGroupName: initialGroupName,
      initialTemplate: initialTemplate,
    );
  }

  Future<void> _showGroupActions(
    FinanceSnapshot snapshot,
    String groupName,
    List<FinanceTemplate> templates,
  ) async {
    final action = await showModalBottomSheet<_TemplateGroupAction>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplateGroupActionSheet(groupName: groupName),
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _TemplateGroupAction.add:
        await _openTemplateComposer(snapshot, initialGroupName: groupName);
      case _TemplateGroupAction.manage:
        await _showGroupTemplatesManager(snapshot, groupName, templates);
      case _TemplateGroupAction.rename:
        await _renameGroup(groupName);
      case _TemplateGroupAction.delete:
        await _confirmDeleteGroup(groupName);
    }
  }

  Future<void> _showGroupTemplatesManager(
    FinanceSnapshot snapshot,
    String groupName,
    List<FinanceTemplate> templates,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _TemplateItemsManagerSheet(
          groupName: groupName,
          templates: templates,
          snapshot: snapshot,
          onAddTap: () async {
            Navigator.of(sheetContext).pop();
            await _openTemplateComposer(snapshot, initialGroupName: groupName);
          },
          onEditTap: (template) async {
            Navigator.of(sheetContext).pop();
            await _openTemplateComposer(snapshot, initialTemplate: template);
          },
          onDeleteTap: (template) async {
            Navigator.of(sheetContext).pop();
            await _confirmDeleteTemplate(template);
          },
        );
      },
    );
  }

  Future<void> _renameGroup(String currentGroupName) async {
    final controller = TextEditingController(text: currentGroupName);
    final renamedGroup = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename group'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Enter a new group name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (!mounted || renamedGroup == null) {
      return;
    }

    final nextGroupName = renamedGroup.trim();
    if (nextGroupName.isEmpty || nextGroupName == currentGroupName) {
      return;
    }

    final wasExpanded = _expandedGroups[currentGroupName] ?? true;
    final success = await widget.controller.renameTemplateGroup(
      oldGroupName: currentGroupName,
      newGroupName: nextGroupName,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(widget.controller.errorMessage ?? 'Unable to rename group.');
      return;
    }

    setState(() {
      _expandedGroups.remove(currentGroupName);
      _expandedGroups[nextGroupName] = wasExpanded;
    });
  }

  Future<void> _confirmDeleteGroup(String groupName) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete group'),
          content: Text(
            'Delete "$groupName" and all templates inside this group?',
          ),
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

    if (!mounted || shouldDelete != true) {
      return;
    }

    final success = await widget.controller.deleteTemplateGroup(groupName);

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(widget.controller.errorMessage ?? 'Unable to delete group.');
      return;
    }

    setState(() {
      _expandedGroups.remove(groupName);
    });
  }

  Future<void> _confirmDeleteTemplate(FinanceTemplate template) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete template'),
          content: Text('Delete "${template.title}" from recurring templates?'),
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

    if (!mounted || shouldDelete != true) {
      return;
    }

    final success = await widget.controller.deleteRecurringTemplate(
      template.id,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage(
        widget.controller.errorMessage ?? 'Unable to delete template.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TemplatesSummaryCard extends StatelessWidget {
  const _TemplatesSummaryCard({
    required this.snapshot,
    required this.currencyCode,
  });

  final FinanceSnapshot snapshot;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      color: _templatesCardSurface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.autorenew_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Monthly recurring total',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF66758C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _formatCurrency(snapshot.recurringMonthlyTotal, currencyCode),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryMiniCard(
                  label: 'Templates',
                  value: '${snapshot.templates.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMiniCard(
                  label: 'Yearly est.',
                  value: _formatCurrency(
                    snapshot.recurringYearlyEstimate,
                    currencyCode,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryMiniCard(
                  label: 'Groups',
                  value: '${_countGroups(snapshot.templates)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _countGroups(List<FinanceTemplate> templates) {
    return templates.map((template) => template.groupName).toSet().length;
  }
}

class _SummaryMiniCard extends StatelessWidget {
  const _SummaryMiniCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _templatesSoftSurface(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: const Color(0xFF66758C),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TemplateGroupCard extends StatelessWidget {
  const _TemplateGroupCard({
    required this.groupName,
    required this.templates,
    required this.currencyCode,
    required this.snapshot,
    required this.isExpanded,
    required this.onToggle,
    required this.onEditTap,
  });

  final String groupName;
  final List<FinanceTemplate> templates;
  final String currencyCode;
  final FinanceSnapshot snapshot;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final monthlyTotal = templates.fold<double>(
      0,
      (sum, template) => sum + template.monthlyEstimate,
    );
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _templatesPanelSurface(context),
        borderRadius: BorderRadius.circular(28),
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
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onToggle,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            groupName,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _templatesSoftSurface(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${templates.length}',
                            style: textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF6F7E95),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_formatCurrency(monthlyTotal, currencyCode)}/mo',
                style: textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF5C6E88),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              _HeaderActionButton(icon: Icons.edit_outlined, onTap: onEditTap),
              const SizedBox(width: 6),
              _HeaderActionButton(
                icon: isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                onTap: onToggle,
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  for (var index = 0; index < templates.length; index++) ...[
                    _TemplateTile(
                      template: templates[index],
                      snapshot: snapshot,
                      currencyCode: currencyCode,
                    ),
                    if (index != templates.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _templatesSoftSurface(context),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF6A7A92)),
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.snapshot,
    required this.currencyCode,
  });

  final FinanceTemplate template;
  final FinanceSnapshot snapshot;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final category = snapshot.findCategory(template.categoryId);
    final textTheme = Theme.of(context).textTheme;
    final subtitleParts = [
      template.interval.label,
      if (template.note.trim().isNotEmpty) template.note.trim(),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _templatesTileSurface(context),
        borderRadius: BorderRadius.circular(22),
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
              color: category?.tone.softColor ?? const Color(0xFFE9EEF5),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: category != null
                ? Text(category.emoji, style: const TextStyle(fontSize: 22))
                : const Icon(
                    Icons.receipt_long_rounded,
                    color: Color(0xFF73819A),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF74839A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatCurrency(template.amount, currencyCode),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TemplatesFab extends StatelessWidget {
  const _TemplatesFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: const Color(0xFF58BE83),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3358BE83),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 38, color: Colors.white),
        ),
      ),
    );
  }
}

class _TemplatesEmptyState extends StatelessWidget {
  const _TemplatesEmptyState();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.autorenew_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No recurring templates yet',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first subscription or repeating purchase with the plus button.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum _TemplateGroupAction { add, manage, rename, delete }

class _TemplateGroupActionSheet extends StatelessWidget {
  const _TemplateGroupActionSheet({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    return _BottomSheetScaffold(
      title: groupName,
      subtitle: 'Group tools',
      child: Column(
        children: [
          _ActionSheetTile(
            icon: Icons.add_circle_outline_rounded,
            label: 'Add template to this group',
            onTap: () => Navigator.of(context).pop(_TemplateGroupAction.add),
          ),
          const SizedBox(height: 10),
          _ActionSheetTile(
            icon: Icons.tune_rounded,
            label: 'Manage templates',
            onTap: () => Navigator.of(context).pop(_TemplateGroupAction.manage),
          ),
          const SizedBox(height: 10),
          _ActionSheetTile(
            icon: Icons.drive_file_rename_outline_rounded,
            label: 'Rename group',
            onTap: () => Navigator.of(context).pop(_TemplateGroupAction.rename),
          ),
          const SizedBox(height: 10),
          _ActionSheetTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete group',
            destructive: true,
            onTap: () => Navigator.of(context).pop(_TemplateGroupAction.delete),
          ),
        ],
      ),
    );
  }
}

class _TemplateItemsManagerSheet extends StatelessWidget {
  const _TemplateItemsManagerSheet({
    required this.groupName,
    required this.templates,
    required this.snapshot,
    required this.onAddTap,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final String groupName;
  final List<FinanceTemplate> templates;
  final FinanceSnapshot snapshot;
  final VoidCallback onAddTap;
  final ValueChanged<FinanceTemplate> onEditTap;
  final ValueChanged<FinanceTemplate> onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final currencyCode = snapshot.accounts.isEmpty
        ? 'KZT'
        : snapshot.accounts.first.currencyCode;

    return _BottomSheetScaffold(
      title: groupName,
      subtitle: 'Manage templates',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAddTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add template'),
            ),
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < templates.length; index++) ...[
            _ManageTemplateTile(
              template: templates[index],
              snapshot: snapshot,
              currencyCode: currencyCode,
              onEditTap: () => onEditTap(templates[index]),
              onDeleteTap: () => onDeleteTap(templates[index]),
            ),
            if (index != templates.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _ManageTemplateTile extends StatelessWidget {
  const _ManageTemplateTile({
    required this.template,
    required this.snapshot,
    required this.currencyCode,
    required this.onEditTap,
    required this.onDeleteTap,
  });

  final FinanceTemplate template;
  final FinanceSnapshot snapshot;
  final String currencyCode;
  final VoidCallback onEditTap;
  final VoidCallback onDeleteTap;

  @override
  Widget build(BuildContext context) {
    final category = snapshot.findCategory(template.categoryId);
    final textTheme = Theme.of(context).textTheme;
    final subtitle = [
      template.interval.label,
      if (template.note.trim().isNotEmpty) template.note.trim(),
    ].join(' - ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _templatesTileSurface(context),
        borderRadius: BorderRadius.circular(22),
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
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: category?.tone.softColor ?? const Color(0xFFE9EEF5),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: category != null
                ? Text(category.emoji, style: const TextStyle(fontSize: 20))
                : const Icon(Icons.receipt_long_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF74839A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(template.amount, currencyCode),
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(width: 8),
          _MiniIconButton(icon: Icons.edit_outlined, onTap: onEditTap),
          const SizedBox(width: 6),
          _MiniIconButton(
            icon: Icons.delete_outline_rounded,
            destructive: true,
            onTap: onDeleteTap,
          ),
        ],
      ),
    );
  }
}

class _BottomSheetScaffold extends StatelessWidget {
  const _BottomSheetScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            color: _templatesSheetSurface(context),
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
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit_note_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: _templatesSoftSurface(context),
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
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.expense : AppColors.ink;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          decoration: BoxDecoration(
            color: destructive
                ? AppColors.expense.withValues(alpha: 0.08)
                : _templatesTileSurface(context),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: destructive
                ? AppColors.expense.withValues(alpha: 0.08)
                : _templatesSoftSurface(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: destructive ? AppColors.expense : const Color(0xFF6A7A92),
          ),
        ),
      ),
    );
  }
}

abstract final class RecurringTemplateComposerSheet {
  static Future<void> show(
    BuildContext context, {
    required FinanceController controller,
    required AppSettingsController settingsController,
    required FinanceSnapshot snapshot,
    String? initialGroupName,
    FinanceTemplate? initialTemplate,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (context) {
        return _RecurringTemplateComposerSheet(
          controller: controller,
          settingsController: settingsController,
          snapshot: snapshot,
          initialGroupName: initialGroupName,
          initialTemplate: initialTemplate,
        );
      },
    );
  }
}

class _RecurringTemplateComposerSheet extends StatefulWidget {
  const _RecurringTemplateComposerSheet({
    required this.controller,
    required this.settingsController,
    required this.snapshot,
    this.initialGroupName,
    this.initialTemplate,
  });

  final FinanceController controller;
  final AppSettingsController settingsController;
  final FinanceSnapshot snapshot;
  final String? initialGroupName;
  final FinanceTemplate? initialTemplate;

  @override
  State<_RecurringTemplateComposerSheet> createState() =>
      _RecurringTemplateComposerSheetState();
}

class _RecurringTemplateComposerSheetState
    extends State<_RecurringTemplateComposerSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _groupController;
  late final TextEditingController _noteController;
  late final List<FinanceCategory> _categories;
  late String _selectedCategoryId;
  late String _selectedAccountId;
  late RecurrenceInterval _selectedInterval;

  bool get _isEditing => widget.initialTemplate != null;

  @override
  void initState() {
    super.initState();
    final initialTemplate = widget.initialTemplate;
    _titleController = TextEditingController(
      text: initialTemplate?.title ?? '',
    );
    _amountController = TextEditingController(
      text: initialTemplate == null
          ? ''
          : _formatEditableAmount(initialTemplate.amount),
    );
    _groupController = TextEditingController(
      text:
          initialTemplate?.groupName ??
          widget.initialGroupName ??
          'Subscriptions',
    );
    _noteController = TextEditingController(text: initialTemplate?.note ?? '');
    _categories = _buildExpenseCategories(widget.snapshot);
    _selectedCategoryId = initialTemplate?.categoryId ?? _categories.first.id;
    _selectedAccountId =
        initialTemplate?.accountId ??
        widget.snapshot.primaryAccount?.id ??
        widget.snapshot.accounts.first.id;
    _selectedInterval = initialTemplate?.interval ?? RecurrenceInterval.monthly;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _groupController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiAccountEnabled =
        widget.settingsController.multiAccountModeEnabled;
    final palette = context.appPalette;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: _templatesSheetSurface(context),
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
                          color: palette.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _isEditing
                              ? Icons.edit_outlined
                              : Icons.autorenew_rounded,
                          size: 18,
                          color: palette.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isEditing
                              ? 'Edit Recurring Template'
                              : 'Add Recurring Template',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: _templatesSoftSurface(context),
                          foregroundColor: AppColors.ink,
                        ),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ComposerFieldLabel(text: 'Name'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'For example, Netflix or Electricity',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ComposerFieldLabel(text: 'Amount'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      prefixText: '$_selectedCurrencyCode ',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ComposerFieldLabel(text: 'Group'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _groupController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Subscriptions, Utilities, Insurance...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ComposerFieldLabel(text: 'Repeat every'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final interval in RecurrenceInterval.values)
                        _IntervalChip(
                          interval: interval,
                          selected: _selectedInterval == interval,
                          onTap: () {
                            setState(() {
                              _selectedInterval = interval;
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ComposerFieldLabel(text: 'Category'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final category in _categories)
                        _ComposerOptionChip(
                          selected: _selectedCategoryId == category.id,
                          onTap: () {
                            setState(() {
                              _selectedCategoryId = category.id;
                            });
                          },
                          leading: Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          label: category.name,
                        ),
                    ],
                  ),
                  if (multiAccountEnabled) ...[
                    const SizedBox(height: 16),
                    _ComposerFieldLabel(text: 'Account'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final account in widget.snapshot.accounts)
                          _ComposerOptionChip(
                            selected: _selectedAccountId == account.id,
                            onTap: () {
                              setState(() {
                                _selectedAccountId = account.id;
                              });
                            },
                            leading: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: palette.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            label: account.name,
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  _ComposerFieldLabel(text: 'Note'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Optional details about this recurring payment',
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Save Changes' : 'Add Template'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String get _selectedCurrencyCode {
    final account = widget.snapshot.findAccount(_selectedAccountId);
    return account?.currencyCode ??
        widget.snapshot.primaryAccount?.currencyCode ??
        'KZT';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final groupName = _groupController.text.trim();
    final amount = double.tryParse(
      _amountController.text.replaceAll(' ', '').replaceAll(',', '.'),
    );

    if (title.isEmpty || groupName.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a name, amount, and group for the template.'),
        ),
      );
      return;
    }

    final success = _isEditing
        ? await widget.controller.updateRecurringTemplate(
            id: widget.initialTemplate!.id,
            title: title,
            amount: amount,
            accountId: _selectedAccountId,
            categoryId: _selectedCategoryId,
            groupName: groupName,
            interval: _selectedInterval,
            note: _noteController.text.trim(),
          )
        : await widget.controller.addRecurringTemplate(
            title: title,
            amount: amount,
            accountId: _selectedAccountId,
            categoryId: _selectedCategoryId,
            groupName: groupName,
            interval: _selectedInterval,
            note: _noteController.text.trim(),
          );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ??
                (_isEditing
                    ? 'Unable to update template.'
                    : 'Unable to add template.'),
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop();
  }

  List<FinanceCategory> _buildExpenseCategories(FinanceSnapshot snapshot) {
    final filtered = snapshot.categoriesOfKind(CategoryKind.expense);
    return filtered.isEmpty ? snapshot.categories : filtered;
  }

  String _formatEditableAmount(double amount) {
    final isWholeNumber = amount == amount.roundToDouble();
    return isWholeNumber
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }
}

class _ComposerFieldLabel extends StatelessWidget {
  const _ComposerFieldLabel({required this.text});

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

class _IntervalChip extends StatelessWidget {
  const _IntervalChip({
    required this.interval,
    required this.selected,
    required this.onTap,
  });

  final RecurrenceInterval interval;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;

    return _ComposerOptionChip(
      selected: selected,
      onTap: onTap,
      leading: Icon(
        Icons.schedule_rounded,
        size: 16,
        color: selected ? palette.primary : const Color(0xFF73819A),
      ),
      label: interval.label,
    );
  }
}

class _ComposerOptionChip extends StatelessWidget {
  const _ComposerOptionChip({
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
    final palette = context.appPalette;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFEFFAF3)
                : _templatesSheetSurface(context),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

String _formatCurrency(double value, String currencyCode) {
  return '$currencyCode ${AppFormatters.groupedNumber(value)}';
}

Color _templatesCardSurface(BuildContext context) {
  return Colors.white;
}

Color _templatesPanelSurface(BuildContext context) {
  return Colors.white;
}

Color _templatesSoftSurface(BuildContext context) {
  return const Color(0xFFF5F7FA);
}

Color _templatesTileSurface(BuildContext context) {
  return Colors.white;
}

Color _templatesSheetSurface(BuildContext context) {
  return Colors.white;
}
