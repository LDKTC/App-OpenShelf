import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/library_provider.dart';

class CategoryManagerScreen extends StatelessWidget {
  const CategoryManagerScreen({super.key});

  Future<void> _promptAddCategory(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(t.newCategoryTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: t.categoryNameField),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.cancel)),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(t.add),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      await context.read<LibraryProvider>().addCategory(name);
    }
  }

  Future<void> _promptRenameCategory(BuildContext context, int id, String currentName) async {
    final controller = TextEditingController(text: currentName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(t.renameCategoryTitle),
          content: TextField(controller: controller, autofocus: true),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t.cancel)),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(t.save),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      final library = context.read<LibraryProvider>();
      final category = library.categories.firstWhere((c) => c.id == id);
      await library.renameCategory(category, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.categoryManagerTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _promptAddCategory(context),
          ),
        ],
      ),
      body: library.categories.isEmpty
          ? Center(child: Text(t.noCategoriesYet))
          : ListView.separated(
              itemCount: library.categories.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final category = library.categories[index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: category.colorValue),
                  title: Text(category.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _promptRenameCategory(
                          context,
                          category.id!,
                          category.name,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => library.deleteCategory(category.id!),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
