import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/class/class_form_controller.dart';
import '../../widgets/searchable_id_dropdown_field.dart';

class ClassFormPage extends StatelessWidget {
  final String? classId;

  const ClassFormPage({super.key, this.classId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClassFormController(classId: classId));

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.isEditMode.value ? 'Editează Clasa' : 'Adaugă Clasă')),
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
                controller: controller.nameController,
                decoration: const InputDecoration(labelText: 'Nume Clasă *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (controller.schoolOptions.isEmpty) {
                  return TextField(
                    controller: controller.schoolIdController,
                    decoration: const InputDecoration(labelText: 'Școală *', border: OutlineInputBorder()),
                    keyboardType: TextInputType.text,
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
                if (controller.teacherOptions.isEmpty) {
                  return TextField(
                    controller: controller.teacherIdController,
                    decoration: const InputDecoration(labelText: 'Profesor (opțional)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.text,
                  );
                }
                return SearchableIdDropdownField(
                  label: 'Profesor (opțional)',
                  value: controller.teacherIdController.text,
                  options: controller.teacherOptions,
                  onChanged: controller.setSelectedTeacherId,
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
                  onPressed: controller.isLoading.value ? null : controller.saveClass,
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