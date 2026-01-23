import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import '../controllers/password_controller.dart';
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  final PasswordController controller = GetIt.instance.get<PasswordController>();

  int _step = 0;
  String? _verifiedCode;
  final _emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');

  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      email.trim().isNotEmpty && _emailRegex.hasMatch(email.trim());

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      Get.snackbar('Error', 'email_invalid_msg'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await controller.sendResetCode(email);

    final msg = controller.message.value.toLowerCase();
    if (msg.contains('trimis') || msg.contains('sent') || msg.contains('cod')) {
      setState(() => _step = 1);
      Get.snackbar('Info', controller.message.value, snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('Error', controller.message.value, snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _resendCode() => _sendCode();

  Future<void> _verifyCode() async {
    final entered = _codeCtrl.text.trim();
    if (entered.length != 6 || int.tryParse(entered) == null) {
      Get.snackbar('Error', 'code_incorrect_msg'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() {
      _verifiedCode = entered;
      _step = 2;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _resetPassword() async {
    final pass = _passwordCtrl.text;
    if (pass.length < 6) {
      Get.snackbar('Error', 'password_min_length'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_verifiedCode == null) {
      Get.snackbar('Error', 'code_missing_msg'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final codeInt = int.tryParse(_verifiedCode!);
    if (codeInt == null) {
      Get.snackbar('Error', 'code_incorrect_msg'.tr, snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await controller.resetPassword(_emailCtrl.text.trim(), codeInt, pass);

    final msg = controller.message.value;
    final low = msg.toLowerCase();
    final succeeded =
        low.contains('resetată') || low.contains('succes') || low.contains('setată') || low.contains('success');

    if (msg.isNotEmpty) {
      Get.snackbar(succeeded ? 'Success' : 'Error', msg, snackPosition: SnackPosition.BOTTOM);
    }

    if (succeeded) {
      Get.to(()=> LoginPage());
    }
  }

  Widget _stepIndicator() {
    Widget stepDot(int index, String label) {
      final active = _step == index;
      return Expanded(
        child: Column(
          children: [
            Container(
              width: active ? 34 : 22,
              height: active ? 34 : 22,
              decoration: BoxDecoration(
                color: active ? Colors.indigoAccent : Colors.grey.shade700,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  active ? Icons.check : Icons.lock_outline,
                  color: Colors.white,
                  size: active ? 18 : 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: active ? Colors.white : Colors.white54,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        stepDot(0, 'email_label'.tr),
        const SizedBox(width: 8),
        stepDot(1, 'enter_code_message'.tr),
        const SizedBox(width: 8),
        stepDot(2, 'change_password'.tr),
      ],
    );
  }

  Widget _buildEmailStep(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'email_label'.tr,
            prefixIcon: const Icon(Icons.email, color: Colors.white70),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: const Color(0xFF22232A),
          ),
          readOnly: loading,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: loading ? null : _sendCode,
            icon: loading ? const SizedBox.shrink() : const Icon(Icons.send),
            label: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('send_code'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeStep(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'enter_code_message'.tr,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '000000',
            hintStyle: const TextStyle(color: Colors.white38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: const Color(0xFF22232A),
            counterText: '',
          ),
          enabled: !loading,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: loading ? null : _verifyCode,
                  child: loading ? const SizedBox.shrink() : Text('verify_code'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: loading ? null : _resendCode,
              child: Text('resend_code'.tr, style: const TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResetStep(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _passwordCtrl,
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'new_password_label'.tr,
            prefixIcon: const Icon(Icons.lock, color: Colors.white70),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off, color: Colors.white70),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: const Color(0xFF22232A),
          ),
          enabled: !loading,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: loading ? null : _resetPassword,
            icon: loading ? const SizedBox.shrink() : const Icon(Icons.check),
            label: loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('change_password'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigoAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = kToolbarHeight + 12.0;
    return Scaffold(
      backgroundColor: const Color(0xFF07080C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('change_password'.tr),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Get.back()),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0B1020), Color(0xFF0F1724)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
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
                  color: const Color(0xFF121318),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 18, offset: Offset(0, 8))],
                ),
                padding: const EdgeInsets.all(18),
                child: Obx(() {
                  final loading = controller.isLoading.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.indigoAccent, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.lock_reset, color: Colors.black87),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('change_password'.tr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                                const SizedBox(height: 6),
                                Text('forgot_password_subtitle'.tr, style: const TextStyle(color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(color: const Color(0xFF0E1115), borderRadius: BorderRadius.circular(10)),
                        child: _stepIndicator(),
                      ),
                      const SizedBox(height: 16),
                      if (_step == 0) _buildEmailStep(loading),
                      if (_step == 1) _buildCodeStep(loading),
                      if (_step == 2) _buildResetStep(loading),
                      const SizedBox(height: 12),
                      if (_step == 0)
                        TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr, style: const TextStyle(color: Colors.white70))),
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
