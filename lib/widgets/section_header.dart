import 'package:flutter/material.dart';

/// A labeled divider between groups of books — the current sort field's
/// group key (a date, series name, or language/genre pair) — used by both
/// the grouped list view and the sectioned shelf views.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
