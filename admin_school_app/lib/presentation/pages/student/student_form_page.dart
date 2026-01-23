import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/student/student_form_controller.dart';
import '../../widgets/searchable_id_dropdown_field.dart';

class StudentFormPage extends StatelessWidget {
  final String? studentId;

  const StudentFormPage({super.key, this.studentId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(StudentFormController(studentId: studentId));

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Editează Elevul' : 'Adaugă Elev')),
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
              Obx(() {
                if (controller.schoolOptions.isEmpty) {
                  return TextField(
                    controller: controller.schoolIdController,
                    decoration: const InputDecoration(labelText: 'Școală *', border: OutlineInputBorder()),
                  );
                }
                return SearchableIdDropdownField(
                  label: 'Școală',
                  isRequired: true,
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
                    decoration: const InputDecoration(labelText: 'Clasă *', border: OutlineInputBorder()),
                  );
                }
                return SearchableIdDropdownField(
                  label: 'Clasă',
                  isRequired: true,
                  value: controller.classIdController.text,
                  options: controller.classOptions,
                  onChanged: controller.setSelectedClassId,
                );
              }),
              const SizedBox(height: 24),
              if (controller.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(controller.errorMessage.value, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value ? null : controller.saveStudent,
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