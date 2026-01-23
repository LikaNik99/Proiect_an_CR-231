import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth/login_controller.dart';
import '../../widgets/auth/login_card.dart';
import '../../widgets/auth/login_header.dart';
import 'forgot_password_page.dart';
import 'set_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LoginController controller = Get.put(LoginController());
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final FocusNode emailFocusNode;
  late final FocusNode passwordFocusNode;

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController(text: controller.email.value);
    passwordController = TextEditingController(text: controller.password.value);
    emailFocusNode = FocusNode()..addListener(() => setState(() {}));
    passwordFocusNode = FocusNode()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final e = email.trim();
    if (e.isEmpty) return false;
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    return regex.hasMatch(e);
  }

  void _handlePrimaryAction() async {
    final emailText = emailController.text.trim();
    controller.errorMessage.value = '';

    if (!_isValidEmail(emailText)) {
      controller.errorMessage.value = 'Introduceți un email valid';
      return;
    }

    controller.email.value = emailText;

    if (controller.showPasswordField.value) {
      controller.password.value = passwordController.text;
      controller.onLogin();
    } else {
      final user = await controller.onCheckEmail();
      if (user != null && (user.isActive == false)) {
        Get.to(() => SetPasswordPage(initialEmail: emailText));
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 800;
    final formWidth = isWide ? 480.0 : size.width - 48.0;
    final topPadding = kToolbarHeight + 32.0;
    final emailHint = (!emailFocusNode.hasFocus && emailController.text.isEmpty)
        ? 'ex: ion.popescu@mail.com'
        : null;

    final emailDecoration = controller.emailDecoration(hint: emailHint);
    final passwordDecoration = controller.passwordDecoration();

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF0B1020), const Color(0xFF121826)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, topPadding, 24, 32),
              child: Column(
                children: [
                  LoginHeader(),

                  const SizedBox(height: 18),
                  Center(
                    child: LoginCard(
                      width: formWidth,
                      controller: controller,
                      emailController: emailController,
                      passwordController: passwordController,
                      emailFocusNode: emailFocusNode,
                      passwordFocusNode: passwordFocusNode,
                      emailDecoration: emailDecoration,
                      passwordDecoration: passwordDecoration,
                      onPrimaryPressed: _handlePrimaryAction,
                      onForgotPassword: () {
                        Get.to(
                          () => ForgotPasswordPage(
                            initialEmail: emailController.text.trim(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      'secure_login_message'.tr,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
