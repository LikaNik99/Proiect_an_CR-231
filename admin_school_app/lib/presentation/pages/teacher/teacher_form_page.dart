import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/teacher/teacher_form_controller.dart';
import '../../widgets/searchable_id_dropdown_field.dart';

class TeacherFormPage extends StatelessWidget {
  final String? teacherId;

  const TeacherFormPage({super.key, this.teacherId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(TeacherFormController(teacherId: teacherId));

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Editează Profesorul' : 'Adaugă Profesor')),
        backgroundColor: Colors.indigo,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.isEditMode.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: controller.usernameController,
                decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.emailController,
                decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.subjectController,
                decoration: const InputDecoration(labelText: 'Specializare (Subject)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.schoolOptions.isEmpty) {
                  return TextField(
                    controller: controller.schoolIdController,
                    decoration: const InputDecoration(labelText: 'Școală (opțional)', border: OutlineInputBorder()),
                  );
                }
                return SearchableIdDropdownField(
                  label: 'Școală (opțional)',
                  value: controller.schoolIdController.text,
                  options: controller.schoolOptions,
                  onChanged: controller.setSelectedSchoolId,
                );
              }),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.classOptions.isEmpty) {
                  return TextField(
                    controller: controller.classIdController,
                    decoration: const InputDecoration(labelText: 'Clasă (opțional)', border: OutlineInputBorder()),
                  );
                }
                return SearchableIdDropdownField(
                  label: 'Clasă (opțional)',
                  value: controller.classIdController.text,
                  options: controller.classOptions,
                  onChanged: controller.setSelectedClassId,
                );
              }),
              const SizedBox(height: 12),
              Obx(
                () => SwitchListTile(
                  value: controller.isHomeroom.value,
                  onChanged: (v) => controller.isHomeroom.value = v,
                  title: const Text('Diriginte', style: TextStyle(color: Colors.white)),
                ),
              ),
              Obx(
                () => SwitchListTile(
                  value: controller.isDirector.value,
                  onChanged: (v) => controller.isDirector.value = v,
                  title: const Text('Director', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              if (controller.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.saveTeacher,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.indigo,
                  ),
                  child: controller.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Salvează'),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}