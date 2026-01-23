import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../../../core/config/app_config.dart';
import '../../../core/database/database_connection_manager.dart';
import '../../../core/services/admin_db_config_service.dart';
import '../../../core/services/connection_mode_service.dart';
import '../../../core/services/secure_storage_service.dart';
import '../../widgets/main_layout.dart';
import '../auth/login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return MainLayout(
      currentPage: 'settings',
      child: Column(
        children: [
          _buildHeader(isMobile),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16 : 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Cont',
                    isMobile: isMobile,
                    children: [
                      _buildSettingTile(
                        icon: Icons.person,
                        title: 'Profil',
                        subtitle: 'Vizualizează și editează profilul tău',
                        onTap: () {
                          Get.snackbar(
                            'În dezvoltare',
                            'Această funcționalitate va fi disponibilă în curând',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        isMobile: isMobile,
                      ),
                      _buildSettingTile(
                        icon: Icons.lock,
                        title: 'Schimbă Parola',
                        subtitle: 'Actualizează parola contului',
                        onTap: () {
                          Get.snackbar(
                            'În dezvoltare',
                            'Această funcționalitate va fi disponibilă în curând',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildSection(
                    title: 'Conexiune',
                    isMobile: isMobile,
                    children: [
                      _buildSettingTile(
                        icon: Icons.storage,
                        title: 'Bază de date (Direct DB)',
                        subtitle: 'Mod Auto / Direct și configurare PostgreSQL',
                        onTap: () => _openDbConfigDialog(context),
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildSection(
                    title: 'Aplicație',
                    isMobile: isMobile,
                    children: [
                      _buildSettingTile(
                        icon: Icons.notifications,
                        title: 'Notificări',
                        subtitle: 'Gestionează preferințele de notificare',
                        onTap: () {
                          Get.snackbar(
                            'În dezvoltare',
                            'Această funcționalitate va fi disponibilă în curând',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        isMobile: isMobile,
                      ),
                      _buildSettingTile(
                        icon: Icons.language,
                        title: 'Limbă',
                        subtitle: 'Română',
                        onTap: () {
                          Get.snackbar(
                            'În dezvoltare',
                            'Această funcționalitate va fi disponibilă în curând',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildSection(
                    title: 'Despre',
                    isMobile: isMobile,
                    children: [
                      _buildSettingTile(
                        icon: Icons.info,
                        title: 'Versiune',
                        subtitle: '1.0.0',
                        onTap: () {},
                        isMobile: isMobile,
                        showArrow: false,
                      ),
                      _buildSettingTile(
                        icon: Icons.help,
                        title: 'Ajutor & Suport',
                        subtitle: 'Documentație și resurse',
                        onTap: () {
                          Get.snackbar(
                            'În dezvoltare',
                            'Această funcționalitate va fi disponibilă în curând',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                  SizedBox(height: isMobile ? 16 : 24),
                  _buildSection(
                    title: 'Sesiune',
                    isMobile: isMobile,
                    children: [
                      _buildSettingTile(
                        icon: Icons.logout,
                        title: 'Deconectare',
                        subtitle: 'Ieși din cont',
                        onTap: () => _showLogoutDialog(context),
                        isMobile: isMobile,
                        iconColor: Colors.red,
                        titleColor: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDbConfigDialog(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    final hostCtrl = TextEditingController(text: AppConfig.dbHost);
    final portCtrl = TextEditingController(text: AppConfig.dbPort.toString());
    final dbCtrl = TextEditingController(text: AppConfig.dbName);
    final userCtrl = TextEditingController(text: AppConfig.dbUser);
    final passCtrl = TextEditingController(text: AppConfig.dbPassword);

    final useSSL = false.obs;
    final mode = ConnectionMode.auto.obs;
    final isTesting = false.obs;
    final testResult = ''.obs;

    Future<void> loadSaved() async {
      final cfg = await AdminDbConfigService.load();
      if (cfg != null) {
        hostCtrl.text = cfg.host;
        portCtrl.text = cfg.port.toString();
        dbCtrl.text = cfg.database;
        userCtrl.text = cfg.username;
        passCtrl.text = cfg.password;
        useSSL.value = cfg.useSSL;
      }
      mode.value = await ConnectionModeService.load();
    }

    Future<void> save() async {
      await AdminDbConfigService.save(
        host: hostCtrl.text.trim(),
        port: int.tryParse(portCtrl.text.trim()) ?? 5432,
        database: dbCtrl.text.trim(),
        username: userCtrl.text.trim(),
        password: passCtrl.text,
        useSSL: useSSL.value,
      );
      await ConnectionModeService.save(mode.value);
    }

    Future<void> testConnection() async {
      isTesting.value = true;
      testResult.value = '';
      try {
        final db = DatabaseConnectionManager();
        await db.disconnect();
        await db.connectToPostgres(
          host: hostCtrl.text.trim(),
          port: int.tryParse(portCtrl.text.trim()) ?? 5432,
          database: dbCtrl.text.trim(),
          username: userCtrl.text.trim(),
          password: passCtrl.text,
          useSSL: useSSL.value,
        );
        testResult.value = 'Conexiune DB reușită.';
      } catch (e) {
        testResult.value = 'Conexiune DB eșuată: $e';
      } finally {
        isTesting.value = false;
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        loadSaved();
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1F3A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
          ),
          title: const Text('Configurare Direct DB', style: TextStyle(color: Colors.white)),
          content: SizedBox(
            width: isMobile ? double.infinity : 520,
            child: Obx(
              () => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!Platform.isWindows)
                      const Text(
                        'Direct DB este suportat oficial doar pe Windows.',
                        style: TextStyle(color: Colors.orangeAccent),
                      ),
                    const SizedBox(height: 8),
                    const Text('Mod conexiune', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ConnectionMode>(
                      value: mode.value,
                      dropdownColor: const Color(0xFF12162F),
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: ConnectionMode.auto, child: Text('Auto (API + fallback DB)')),
                        DropdownMenuItem(value: ConnectionMode.directDb, child: Text('Direct DB (fără API)')),
                      ],
                      onChanged: (v) {
                        if (v != null) mode.value = v;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('PostgreSQL', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    _field(hostCtrl, 'Host'),
                    const SizedBox(height: 10),
                    _field(portCtrl, 'Port', keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    _field(dbCtrl, 'Database'),
                    const SizedBox(height: 10),
                    _field(userCtrl, 'Username'),
                    const SizedBox(height: 10),
                    _field(passCtrl, 'Password', obscure: true),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: useSSL.value,
                      onChanged: (v) => useSSL.value = v,
                      title: const Text('Use SSL', style: TextStyle(color: Colors.white)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                    if (testResult.value.isNotEmpty)
                      Text(
                        testResult.value,
                        style: TextStyle(
                          color: testResult.value.startsWith('Conexiune DB reușită')
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Închide'),
            ),
            TextButton(
              onPressed: isTesting.value
                  ? null
                  : () async {
                      await save();
                      Get.snackbar('Salvat', 'Configurația DB a fost salvată');
                    },
              child: const Text('Salvează'),
            ),
            ElevatedButton(
              onPressed: isTesting.value ? null : testConnection,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: isTesting.value
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Test Connection'),
            ),
          ],
        );
      },
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.indigo),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 16 : 24,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E1A),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Setări',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configurare sistem și preferințe',
            style: TextStyle(
              color: Colors.white54,
              fontSize: isMobile ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F3A),
            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isMobile,
    bool showArrow = true,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 14 : 16,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.indigo).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? Colors.indigo,
                  size: isMobile ? 20 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: titleColor ?? Colors.white,
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: isMobile ? 12 : 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: isMobile ? 20 : 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        ),
        title: const Text(
          'Deconectare',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ești sigur că vrei să te deconectezi?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () async {
              await SecureStorageService.deleteToken();
              Get.offAll(() => const LoginPage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Deconectare'),
          ),
        ],
      ),
    );
  }
}