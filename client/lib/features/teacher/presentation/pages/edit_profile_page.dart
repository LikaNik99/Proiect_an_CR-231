import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/teacher_dashboard_controller.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/config/app_config.dart';

class EditProfilePage extends StatefulWidget {
  final TeacherDashboardController controller;

  const EditProfilePage({super.key, required this.controller});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _isLoading = false;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    final teacher = widget.controller.teacher.value;
    _usernameController = TextEditingController(text: teacher?.username ?? '');
    _emailController = TextEditingController(text: teacher?.email ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (pickedFile != null) {
      setState(() => _selectedImagePath = pickedFile.path);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final dio = await DioClient.getInstance();


      final response = await dio.put('/users/me/profile', data: {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      if (response.statusCode == 200) {

        if (_selectedImagePath != null) {
          await widget.controller.uploadAvatar(_selectedImagePath!);
        }


        await widget.controller.fetchCurrentTeacher();

        Get.snackbar(
          'Succes',
          'Profilul a fost actualizat cu succes',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withOpacity(0.9),
          colorText: Colors.white,
        );
        Get.back();
      }
    } catch (e) {
      String errorMessage = 'Nu s-a putut actualiza profilul';
      if (e.toString().contains('400')) {
        if (e.toString().contains('Email already in use')) {
          errorMessage = 'Acest email este deja folosit';
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
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editează profilul', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                  )
                : const Text('Salvează', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF0F1419),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              _buildAvatarSection(),
              const SizedBox(height: 32),


              _buildTextField(
                controller: _usernameController,
                label: 'Nume utilizator',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Numele este obligatoriu';
                  }
                  if (value.trim().length < 3) {
                    return 'Numele trebuie să aibă minim 3 caractere';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email-ul este obligatoriu';
                  }
                  if (!GetUtils.isEmail(value.trim())) {
                    return 'Introdu un email valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),


              Obx(() {
                final subject = widget.controller.teacher.value?.subject;
                if (subject == null) return const SizedBox.shrink();
                return _buildReadOnlyField(
                  label: 'Materie',
                  value: subject,
                  icon: Icons.book_outlined,
                );
              }),

              const SizedBox(height: 32),


              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blueAccent[200], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Unele informații pot fi modificate doar de către administrator.',
                        style: TextStyle(
                          color: Colors.blueAccent[200],
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

  Widget _buildAvatarSection() {
    return Obx(() {
      final teacher = widget.controller.teacher.value;
      final avatarUrl = teacher?.avatarUrl;

      ImageProvider? imageProvider;
      if (_selectedImagePath != null) {
        imageProvider = FileImage(File(_selectedImagePath!));
      } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
        final fullUrl = avatarUrl.startsWith('/') ? '${AppConfig.baseUrl}$avatarUrl' : avatarUrl;
        imageProvider = NetworkImage(fullUrl);
      }

      return Column(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: imageProvider == null
                        ? const LinearGradient(
                            colors: [Colors.blueAccent, Colors.purpleAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: imageProvider != null
                        ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                        : null,
                  ),
                  child: imageProvider == null
                      ? Center(
                          child: Text(
                            teacher?.username.isNotEmpty == true
                                ? teacher!.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0F1419), width: 3),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Apasă pentru a schimba fotografia',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      );
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
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
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[500]),
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
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[800]!),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Text(
                value,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),
              const Spacer(),
              Icon(Icons.lock_outline, color: Colors.grey[700], size: 18),
            ],
          ),
        ),
      ],
    );
  }
}
