import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/ui/input_decorations.dart' as ui_decorations;
import '../../controllers/auth/password_controller.dart';
import 'login_page.dart';

class SetPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const SetPasswordPage({super.key, this.initialEmail});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final PasswordController controller = Get.put(PasswordController());

  int _step = 0;
  String? _verifiedCode;

  @override
  void initState() {
    super.initState();
    _emailCtrl.text = widget.initialEmail ?? '';
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onContinueEmail() async {
    final email = _emailCtrl.text.trim();
    await controller.sendActivationCode(email);
    final msg = controller.message.value.toLowerCase();
    if (msg.contains('trimis') || msg.contains('cod')) {
      setState(() => _step = 1);
      FocusScope.of(context).unfocus();
      Get.snackbar(
        'Info',
        controller.message.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Eroare',
        controller.message.value,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _onVerifyCode() async {
    final entered = _codeCtrl.text.trim();
    if (entered.length != 6 || int.tryParse(entered) == null) {
      Get.snackbar(
        'Eroare',
        'code_incorrect_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    setState(() {
      _verifiedCode = entered;
      _step = 2;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _onSetPassword() async {
    final pass = _passwordCtrl.text;
    if (_verifiedCode == null) {
      Get.snackbar(
        'Eroare',
        'code_missing_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final codeInt = int.tryParse(_verifiedCode!);
    if (codeInt == null) {
      Get.snackbar(
        'Eroare',
        'code_incorrect_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    await controller.setPassword(_emailCtrl.text.trim(), codeInt, pass);

    final msg = controller.message.value;
    final low = msg.toLowerCase();

    final succeeded =
        low.contains('setată') ||
        low.contains('activat') ||
        low.contains('succes');

    if (msg.isNotEmpty) {
      Get.snackbar(
        succeeded ? 'Succes' : 'Eroare',
        msg,
        snackPosition: SnackPosition.BOTTOM,
      );
    }

    if (succeeded) {
      Get.to(() => LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = kToolbarHeight + 12.0;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('seteaza_parola'.tr),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1020), Color(0xFF121826)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2028),
                  borderRadius: BorderRadius.circular(12),
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
                child: Obx(() {
                  final loading = controller.isLoading.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'seteaza_parola'.tr,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _step == 0
                            ? 'enter_email_activation'.tr
                            : _step == 1
                            ? 'enter_code_activation'.tr
                            : 'enter_new_password'.tr,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: ui_decorations.buildInputDecoration(
                          label: 'email_label'.tr,
                          icon: Icons.email,
                          hint: null,
                          fillColor: const Color(0xFF23232E),
                          borderColor: Colors.white10,
                          focusedColor: Colors.indigo,
                        ),
                        readOnly: loading,
                      ),
                      const SizedBox(height: 12),
                      if (_step == 1) ...[
                        TextField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          style: const TextStyle(color: Colors.white),
                          decoration: ui_decorations.buildInputDecoration(
                            label: 'code_label'.tr,
                            icon: Icons.vpn_key,
                            hint: '000000',
                            fillColor: const Color(0xFF23232E),
                            borderColor: Colors.white10,
                            focusedColor: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: loading ? null : _onVerifyCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.indigoAccent.shade200,
                                    foregroundColor: Colors.black87,
                                  ),
                                  child: loading
                                      ? const SizedBox.shrink()
                                      : Text('verify_button'.tr),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => controller.sendActivationCode(
                                      _emailCtrl.text.trim(),
                                    ),
                              child: Text(
                                'resend_code'.tr,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_step == 2) ...[
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: ui_decorations.buildInputDecoration(
                            label: 'enter_new_password'.tr,
                            icon: Icons.lock,
                            hint: null,
                            fillColor: const Color(0xFF23232E),
                            borderColor: Colors.white10,
                            focusedColor: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: loading ? null : _onSetPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent.shade200,
                              foregroundColor: Colors.black87,
                            ),
                            child: loading
                                ? const SizedBox.shrink()
                                : Text('set_password_button'.tr),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      if (_step == 0) ...[
                        if (controller.isLoading.value)
                          const SizedBox(
                            height: 48,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _onContinueEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigoAccent.shade200,
                                foregroundColor: Colors.black87,
                              ),
                              child: Text('continue_button'.tr),
                            ),
                          ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => Get.back(),
                          child: Text(
                            'cancel'.tr,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
