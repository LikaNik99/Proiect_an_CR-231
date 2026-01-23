import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school/school_form_controller.dart';

class SchoolFormPage extends StatelessWidget {
  final String? schoolId;

  const SchoolFormPage({super.key, this.schoolId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchoolFormController(schoolId: schoolId));

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.isEditMode.value ? 'Editează Școala' : 'Adaugă Școală',
            )),
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
                decoration: const InputDecoration(
                  labelText: 'Nume Școală *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.locationController,
                decoration: const InputDecoration(
                  labelText: 'Locație',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.websiteController,
                decoration: const InputDecoration(
                  labelText: 'Website',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.logoUrlController,
                decoration: const InputDecoration(
                  labelText: 'URL Logo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller.establishedYearController,
                decoration: const InputDecoration(
                  labelText: 'An Înființare',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Obx(() => SwitchListTile(
                title: const Text('Activă'),
                value: controller.isActive.value,
                onChanged: (value) => controller.isActive.value = value,
                activeColor: Colors.indigo,
              )),
              const SizedBox(height: 24),
              if (controller.errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    controller.errorMessage.value,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : controller.saveSchool,
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