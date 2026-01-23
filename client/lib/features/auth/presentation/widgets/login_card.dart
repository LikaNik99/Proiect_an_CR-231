import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/login_controller.dart';
import 'email_field.dart';
import 'password_field.dart';
import 'primary_button.dart';

class LoginCard extends StatelessWidget {
  final double width;
  final LoginController controller;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocusNode;
  final FocusNode passwordFocusNode;
  final InputDecoration emailDecoration;
  final InputDecoration passwordDecoration;
  final VoidCallback onPrimaryPressed;
  final VoidCallback onForgotPassword;

  const LoginCard({
    Key? key,
    required this.width,
    required this.controller,
    required this.emailController,
    required this.passwordController,
    required this.emailFocusNode,
    required this.passwordFocusNode,
    required this.emailDecoration,
    required this.passwordDecoration,
    required this.onPrimaryPressed,
    required this.onForgotPassword,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2028),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Text(
            'login_title'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          EmailField(
            controller: emailController,
            focusNode: emailFocusNode,
            decoration: emailDecoration,
            onEditingComplete: () =>
                FocusScope.of(context).requestFocus(passwordFocusNode),
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (!controller.showPasswordField.value)
              return const SizedBox.shrink();
            return Column(
              children: [
                PasswordField(
                  controller: passwordController,
                  focusNode: passwordFocusNode,
                  decoration: passwordDecoration,
                  isHidden: controller.isPasswordHidden.value,
                  toggleVisibility: controller.togglePasswordVisibility,
                  onSubmitted: (_) => onPrimaryPressed(),
                ),
                const SizedBox(height: 12),
              ],
            );
          }),
          Obx(() {
            if (controller.errorMessage.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                controller.errorMessage.value,
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }),
          Obx(
            () => PrimaryButton(
              isLoading: controller.isLoading.value,
              showPasswordField: controller.showPasswordField.value,
              onPressed: onPrimaryPressed,
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            if (!controller.showPasswordField.value)
              return const SizedBox.shrink();
            return Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onForgotPassword,
                child: Text(
                  'forgot_password'.tr,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
