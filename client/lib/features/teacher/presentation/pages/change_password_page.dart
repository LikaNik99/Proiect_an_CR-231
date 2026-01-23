import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/dio_client.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentCtrl = TextEditingController();
  final TextEditingController _newCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_newCtrl.text != _confirmCtrl.text) {
      Get.snackbar(
        'Eroare',
        'Parolele noi nu coincid',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final dio = await DioClient.getInstance();
      final response = await dio.post('/password/change', data: {
        'current_password': _currentCtrl.text,
        'new_password': _newCtrl.text,
      });

      if (response.statusCode == 200) {
        Get.snackbar(
          'Succes',
          'Parola a fost schimbată cu succes',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
        _currentCtrl.clear();
        _newCtrl.clear();
        _confirmCtrl.clear();
        Get.back();
      }
    } catch (e) {
      String errorMessage = 'Nu s-a putut schimba parola';
      if (e.toString().contains('400')) {
        if (e.toString().contains('incorectă')) {
          errorMessage = 'Parola curentă este incorectă';
        } else if (e.toString().contains('diferită')) {
          errorMessage = 'Parola nouă trebuie să fie diferită';
        } else {
          errorMessage = 'Parola curentă este incorectă';
        }
      }
      Get.snackbar(
        'Eroare',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.9),
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schimbă parola', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F1419),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Actualizează parola contului tău',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 32),


              _buildPasswordField(
                controller: _currentCtrl,
                label: 'Parola curentă',
                hint: 'Introdu parola curentă',
                showPassword: _showCurrentPassword,
                onToggleVisibility: () => setState(() => _showCurrentPassword = !_showCurrentPassword),
                validator: (v) => (v == null || v.isEmpty) ? 'Introdu parola curentă' : null,
              ),
              const SizedBox(height: 16),


              _buildPasswordField(
                controller: _newCtrl,
                label: 'Parola nouă',
                hint: 'Minim 6 caractere',
                showPassword: _showNewPassword,
                onToggleVisibility: () => setState(() => _showNewPassword = !_showNewPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Introdu parola nouă';
                  if (v.length < 6) return 'Minim 6 caractere';
                  return null;
                },
              ),
              const SizedBox(height: 16),


              _buildPasswordField(
                controller: _confirmCtrl,
                label: 'Confirmă parola',
                hint: 'Repetă parola nouă',
                showPassword: _showConfirmPassword,
                onToggleVisibility: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirmă parola';
                  if (v != _newCtrl.text) return 'Parolele nu coincid';
                  return null;
                },
              ),
              const SizedBox(height: 32),


              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.blueAccent.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Schimbă parola',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),


              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[300], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'După schimbarea parolei, vei rămâne autentificat pe acest dispozitiv.',
                        style: TextStyle(
                          color: Colors.orange[300],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool showPassword,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !showPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF1A1F26),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey[500],
              ),
              onPressed: onToggleVisibility,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
