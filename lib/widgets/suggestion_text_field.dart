import 'package:flutter/material.dart';

/// A text field with a dropdown of previously-used values, so filling in a
/// field someone has typed before (an author, a publisher, a series...) is
/// a tap instead of retyping it.
///
/// For [multiValue] fields (comma-separated, e.g. authors/illustrators),
/// [suggestions] are individual previously-used tokens and picking one is
/// appended to the field instead of replacing it, since the field holds
/// more than one value at a time.
class SuggestionTextField extends StatefulWidget {
  const SuggestionTextField({
    super.key,
    required this.controller,
    required this.suggestions,
    required this.decoration,
    this.multiValue = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final Iterable<String> suggestions;
  final InputDecoration decoration;
  final bool multiValue;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  State<SuggestionTextField> createState() => _SuggestionTextFieldState();
}

class _SuggestionTextFieldState extends State<SuggestionTextField> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// The text already entered before the cursor's current comma-separated
  /// segment, for [multiValue] fields — used both to know what's already
  /// chosen (so it isn't suggested again) and to know what to keep when a
  /// suggestion is applied.
  List<String> get _priorSegments {
    final parts = widget.controller.text.split(',');
    return parts.take(parts.length - 1).toList();
  }

  Iterable<String> _optionsFor(TextEditingValue value) {
    if (!widget.multiValue) {
      final query = value.text.trim().toLowerCase();
      return widget.suggestions.where(
        (s) => s.toLowerCase() != query && s.toLowerCase().contains(query),
      );
    }

    final query = value.text.split(',').last.trim().toLowerCase();
    final chosen = _priorSegments.map((p) => p.trim().toLowerCase()).toSet();
    return widget.suggestions.where(
      (s) =>
          s.toLowerCase() != query &&
          s.toLowerCase().contains(query) &&
          !chosen.contains(s.toLowerCase()),
    );
  }

  void _select(String selection) {
    if (!widget.multiValue) {
      widget.controller.value = TextEditingValue(
        text: selection,
        selection: TextSelection.collapsed(offset: selection.length),
      );
      return;
    }

    final text =
        '${[..._priorSegments.map((p) => p.trim()), selection].join(', ')}, ';
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: _optionsFor,
      onSelected: _select,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: widget.decoration,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          maxLines: widget.maxLines,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              // Assumes the field sits in a 16px-padded column (true for
              // every current call site) — RawAutocomplete's overlay isn't
              // otherwise told the field's actual width.
              width: MediaQuery.sizeOf(context).width - 32,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      dense: true,
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
