import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/school/schools_controller.dart';
import '../../widgets/main_layout.dart';
import 'school_form_page.dart';
import '../settings/settings_page.dart';

class SchoolsPage extends StatelessWidget {
  const SchoolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SchoolsController());
    final isMobile = MediaQuery.of(context).size.width < 800;

    return MainLayout(
      currentPage: 'schools',
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const SchoolFormPage()),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            'Adaugă Școală',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: Colors.white));
              }

              if (controller.errorMessage.isNotEmpty) {
                return _buildError(controller);
              }

              if (controller.schools.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: controller.loadSchools,
                backgroundColor: const Color(0xFF1A1F3A),
                color: const Color(0xFF3B82F6),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: isMobile
                      ? ListView.builder(
                    itemCount: controller.schools.length,
                    itemBuilder: (context, index) {
                      final school = controller.schools[index];
                      return _buildMobileCard(controller, school);
                    },
                  )
                      : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: _buildDataTable(controller),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Școli',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Gestionare instituții educaționale',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCard(SchoolsController controller, school) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: const Color(0xFF1A1F3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              school.name,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('ID: ${school.id ?? "-"}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            Text('Adresă: ${school.location ?? "-"}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            Text('Telefon: ${school.phone ?? "-"}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            Text('Email: ${school.email ?? "-"}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => SchoolFormPage(schoolId: school.id)),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editează'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showDeleteDialog(controller, school.id!),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Șterge'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(SchoolsController controller) {
    return DataTable(
      headingRowColor: WidgetStateProperty.all(const Color(0xFF3B82F6).withOpacity(0.15)),
      headingRowHeight: 60,
      headingTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      dataTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.8),
        fontSize: 14,
      ),
      columns: const [
        DataColumn(label: Text('ID')),
        DataColumn(label: Text('Nume')),
        DataColumn(label: Text('Adresă')),
        DataColumn(label: Text('Telefon')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Acțiuni')),
      ],
      rows: controller.schools.map((school) {
        return DataRow(cells: [
          DataCell(Text(school.id?.toString() ?? '-')),
          DataCell(Text(school.name)),
          DataCell(Text(school.location ?? '-')),
          DataCell(Text(school.phone ?? '-')),
          DataCell(Text(school.email ?? '-')),
          DataCell(Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: () => Get.to(() => SchoolFormPage(schoolId: school.id)),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _showDeleteDialog(controller, school.id!),
              ),
            ],
          )),
        ]);
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Icon(
              Icons.school_outlined,
              size: 64,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nu există școli',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Apasă butonul + pentru a adăuga prima școală',
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(SchoolsController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
          ),
          const SizedBox(height: 16),
          Text(
            controller.errorMessage.value,
            style: const TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: controller.loadSchools,
                icon: const Icon(Icons.refresh),
                label: const Text('Reîncearcă'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => Get.to(() => const SettingsPage()),
                icon: const Icon(Icons.settings),
                label: const Text('Setări DB'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1F3A),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(SchoolsController controller, String schoolId) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Confirmare Ștergere',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Sigur doriți să ștergeți această școală?\nAceastă acțiune nu poate fi anulată.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Get.back(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Anulează', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.deleteSchool(schoolId);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Șterge', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
