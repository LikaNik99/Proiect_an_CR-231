import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/config/app_config.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/student.dart';
import '../../data/model/material_model.dart';

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  StudentDataApi? _api;
  StudentModel? _student;
  List<MaterialModel> _materials = [];
  bool _isLoading = true;
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final dio = await DioClient.getInstance();
      _api = StudentDataApi(dio);

      _student = await _api?.getMe();
      if (_student != null && _student!.classId.isNotEmpty) {
        _materials = await _api?.getClassMaterials(_student!.classId) ?? [];
      }
    } catch (e) {
      debugPrint('Error loading materials: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1419),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Materiale',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.blueAccent),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Colors.blueAccent,
              backgroundColor: const Color(0xFF1A1F26),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildSubjectFilter()),
                  SliverToBoxAdapter(child: _buildMaterialsList()),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_open, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Materiale educaționale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_materials.length} ${_materials.length == 1 ? 'material' : 'materiale'} disponibile',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectFilter() {
    final subjects = _materials.map((m) => m.subjectName ?? 'Necunoscut').toSet().toList();
    if (subjects.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip('Toate', null),
          ...subjects.map((subject) => _buildFilterChip(subject, subject)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedSubject == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSubject = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent : const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blueAccent : Colors.grey[700]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialsList() {
    List<MaterialModel> filteredMaterials = _materials;
    if (_selectedSubject != null) {
      filteredMaterials = _materials
          .where((m) => m.subjectName == _selectedSubject)
          .toList();
    }

    if (filteredMaterials.isEmpty) {
      return _buildEmptyState();
    }


    final Map<String, List<MaterialModel>> grouped = {};
    for (var material in filteredMaterials) {
      final subject = material.subjectName ?? 'Necunoscut';
      if (!grouped.containsKey(subject)) {
        grouped[subject] = [];
      }
      grouped[subject]!.add(material);
    }

    return Column(
      children: grouped.entries.map((entry) {
        return _buildSubjectSection(entry.key, entry.value);
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_off_outlined,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Nu există materiale',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Materialele vor apărea aici când profesorii le vor încărca',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectSection(String subject, List<MaterialModel> materials) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getSubjectColor(subject).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.school,
                    color: _getSubjectColor(subject),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${materials.length}',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...materials.map((material) => _buildMaterialCard(material)),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(MaterialModel material) {
    final extension = material.fileName.split('.').last.toLowerCase();
    IconData icon;
    Color iconColor;

    switch (extension) {
      case 'pdf':
        icon = Icons.picture_as_pdf;
        iconColor = const Color(0xFFEF4444);
        break;
      case 'doc':
      case 'docx':
        icon = Icons.description;
        iconColor = const Color(0xFF3B82F6);
        break;
      case 'ppt':
      case 'pptx':
        icon = Icons.slideshow;
        iconColor = const Color(0xFFF59E0B);
        break;
      case 'xls':
      case 'xlsx':
        icon = Icons.table_chart;
        iconColor = const Color(0xFF10B981);
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        icon = Icons.image;
        iconColor = const Color(0xFFA855F7);
        break;
      case 'mp4':
      case 'avi':
      case 'mov':
        icon = Icons.video_file;
        iconColor = const Color(0xFFEC4899);
        break;
      default:
        icon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () => _openMaterial(material),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        extension.toUpperCase(),
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (material.fileSize != null) ...[
                        Text(
                          ' • ${_formatFileSize(material.fileSize!)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                      Text(
                        ' • ${DateFormat('dd.MM.yyyy').format(material.createdAt)}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                  if (material.description != null && material.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      material.description!,
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.download,
                color: Colors.blueAccent,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Color _getSubjectColor(String subjectName) {
    final colors = [
      const Color(0xFFA855F7),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
      const Color(0xFF6366F1),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
    ];
    return colors[subjectName.hashCode % colors.length];
  }

  Future<void> _openMaterial(MaterialModel material) async {
    final url = material.fileUrl.startsWith('/')
        ? '${AppConfig.baseUrl}${material.fileUrl}'
        : material.fileUrl;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Eroare',
          'Nu se poate deschide fișierul',
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint('Error opening material: $e');
      Get.snackbar(
        'Eroare',
        'Nu se poate deschide fișierul',
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
