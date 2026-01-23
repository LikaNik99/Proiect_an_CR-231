import 'package:flutter/material.dart';
import 'package:get/get.dart';

InputDecoration buildInputDecoration({
  required String label,
  required IconData icon,
  String? hint,
  Color fillColor = const Color(0xFF23232E),
  Color borderColor = const Color(0x1AFFFFFF),
  Color focusedColor = Colors.indigo,
}) {
  return InputDecoration(
    labelText: label,
    floatingLabelBehavior: FloatingLabelBehavior.auto,
    labelStyle: const TextStyle(
      color: Colors.white70,
      fontWeight: FontWeight.w600,
    ),
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white38),
    filled: true,
    fillColor: fillColor,
    prefixIcon: Icon(icon, color: Colors.white54),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor, width: 1),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: focusedColor, width: 1.4),
    ),
  );
}
