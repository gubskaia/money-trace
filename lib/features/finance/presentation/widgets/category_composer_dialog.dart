import 'package:flutter/material.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';

class CategoryComposerDialog extends StatefulWidget {
  const CategoryComposerDialog({super.key, required this.controller});

  final FinanceController controller;

  static Future<void> show(
    BuildContext context, {
    required FinanceController controller,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => CategoryComposerDialog(controller: controller),
    );
  }

  @override
  State<CategoryComposerDialog> createState() => _CategoryComposerDialogState();
}

class _CategoryComposerDialogState extends State<CategoryComposerDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emojiController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emojiController = TextEditingController();
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
      title: const Text('New category'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'For example, Travel',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emojiController,
              decoration: const InputDecoration(
                labelText: 'Emoji',
                hintText: 'Optional, for example ✈',
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
        FilledButton(onPressed: _save, child: const Text('Add')),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name cannot be empty.')),
      );
      return;
    }

    await widget.controller.addCategory(
      name: name,
      emoji: _emojiController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }
}
