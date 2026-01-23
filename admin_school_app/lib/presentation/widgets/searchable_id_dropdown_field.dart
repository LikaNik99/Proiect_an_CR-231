import 'package:flutter/material.dart';

import 'id_dropdown_field.dart';

/// Searchable dropdown for large lookup lists.
/// Shows only option labels; stores `id` as value.
class SearchableIdDropdownField extends StatelessWidget {
  final String label;
  final bool isRequired;
  final String? value;
  final List<IdDropdownOption> options;
  final ValueChanged<String?> onChanged;
  final bool enabled;

  const SearchableIdDropdownField({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final selected = (value != null && value!.isNotEmpty)
        ? options.where((o) => o.id == value).cast<IdDropdownOption?>().firstWhere(
              (o) => o != null,
              orElse: () => null,
            )
        : null;

    final textController = TextEditingController(text: selected?.label ?? '');

    return Autocomplete<IdDropdownOption>(
      initialValue: TextEditingValue(text: selected?.label ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        final q = textEditingValue.text.toLowerCase();
        return options.where((o) => o.label.toLowerCase().contains(q));
      },
      displayStringForOption: (o) => o.label,
      onSelected: enabled
          ? (o) {
              onChanged(o.id);
            }
          : null,
      fieldViewBuilder: (context, fieldTextController, focusNode, onFieldSubmitted) {

        if (fieldTextController.text.isEmpty && textController.text.isNotEmpty) {
          fieldTextController.text = textController.text;
        }

        return TextField(
          controller: fieldTextController,
          focusNode: focusNode,
          enabled: enabled,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.search),
          ),
        );
      },
    );
  }
}
