import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final InputDecoration decoration;
  final VoidCallback? onEditingComplete;

  const EmailField({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.decoration,
    this.onEditingComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: Colors.white),
      decoration: decoration,
      onEditingComplete: onEditingComplete,
    );
  }
}

