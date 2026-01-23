import 'package:flutter/material.dart';

class IdDropdownOption {
  final String id;
  final String label;

  const IdDropdownOption({required this.id, required this.label});

  @override
  String toString() => label;
}

/// A reusable dropdown field for selecting an entity id (UUID/string)
/// while showing a human-friendly label.
class IdDropdownField extends StatelessWidget {
  final String label;
  final String? value;
  final List<IdDropdownOption> options;
  final bool isRequired;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  const IdDropdownField({
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
    return DropdownButtonFormField<String>(
      value: (value != null && value!.isNotEmpty) ? value : null,
      items: options
          .map(
            (o) => DropdownMenuItem<String>(
              value: o.id,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        border: const OutlineInputBorder(),
      ),
      isExpanded: true,
    );
  }
}
