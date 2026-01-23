import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrimaryButton extends StatelessWidget {
  final bool isLoading;
  final bool showPasswordField;
  final VoidCallback onPressed;

  const PrimaryButton({
    Key? key,
    required this.isLoading,
    required this.showPasswordField,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.indigoAccent.shade200,
        ),
        child: Text(
          showPasswordField ? 'login_button'.tr : 'continue_button'.tr,
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

