import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;
  final bool isHidden;
  final VoidCallback toggleVisibility;
  final ValueChanged<String>? onSubmitted;

  const PasswordField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.decoration,
    required this.isHidden,
    required this.toggleVisibility,
    this.onSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      controller: controller,
      obscureText: isHidden,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: Colors.white),
      onSubmitted: onSubmitted,
      decoration: decoration.copyWith(
        suffixIcon: IconButton(
          icon: Icon(isHidden ? Icons.visibility_off : Icons.visibility, color: Colors.white54),
          onPressed: toggleVisibility,
        ),
      ),
    );
  }
}

