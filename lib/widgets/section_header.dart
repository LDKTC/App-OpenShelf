import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// A labeled divider between groups of books — the current sort field's
/// group key (a date, series name, or language/genre pair) — used by both
/// the grouped list view and the sectioned shelf views.
///
/// When [onToggleExpanded] is given, the header also shows an expand/collapse
/// affordance for the shelf views' per-section row-vs-grid toggle.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.label,
    this.isExpanded = false,
    this.onToggleExpanded,
  });

  final String label;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final toggle = onToggleExpanded;
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.only(left: 16, right: 4, top: 2, bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          if (toggle != null)
            IconButton(
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              tooltip: isExpanded
                  ? t.collapseSectionTooltip
                  : t.expandSectionTooltip,
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: toggle,
            ),
        ],
      ),
    );
  }
}
