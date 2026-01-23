import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasource/student_data_api.dart';
import '../../data/model/homework_model.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  StudentDataApi? _api;
  List<HomeworkModel> _homeworks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_api == null) {
        final dio = await DioClient.getInstance();
        _api = StudentDataApi(dio);
      }

      final student = await _api!.getMe();
      if (student == null || student.classId.isEmpty) {
        setState(() {
          _errorMessage = 'Nu s-a putut obține clasa studentului';
          _isLoading = false;
        });
        return;
      }

      final homeworks = await _api!.getMyHomework();
      setState(() {
        _homeworks = homeworks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Eroare la încărcarea temelor: $e';
        _isLoading = false;
      });
    }
  }

  String _formatCreatedDate(DateTime createdAt) {
    return 'Trimis: ${DateFormat('dd MMM yyyy').format(createdAt)}';
  }

  String _formatDueDate(DateTime dueDate) {
    return 'Termen: ${DateFormat('dd MMM yyyy').format(dueDate)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('homework_page_title'.tr),
        backgroundColor: const Color(0xFF0F172A),
      ),
      backgroundColor: const Color(0xFF0B0B0D),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHomework,
                        child: const Text('Reîncearcă'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHomework,
                  child: _homeworks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.assignment, size: 64, color: Colors.white24),
                              const SizedBox(height: 16),
                              Text(
                                'Nu există teme pentru moment',
                                style: const TextStyle(color: Colors.white70, fontSize: 18),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _homeworks.length,
                          itemBuilder: (context, index) {
                            final homework = _homeworks[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1A1C20), Color(0xFF111827)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white10,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      homework.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.book, size: 16, color: Colors.blue),
                                        const SizedBox(width: 6),
                                        Text(
                                          homework.subjectName,
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (homework.description != null && homework.description!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        homework.description!,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    const Divider(color: Colors.white10, height: 1),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.send,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatCreatedDate(homework.createdAt),
                                          style: const TextStyle(
                                            color: Colors.blue,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 16,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatDueDate(homework.dueDate),
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
