import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/teacher_dashboard_controller.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../auth/presentation/pages/login_page.dart';
import 'change_password_page.dart';
import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  final TeacherDashboardController controller;

  const SettingsPage({super.key, required this.controller});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkMode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setări', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1A1F26),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0F1419),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildSectionHeader('Cont', Icons.person_outline),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildNavigationItem(
                icon: Icons.lock_outline,
                iconColor: Colors.blueAccent,
                title: 'Schimbă parola',
                subtitle: 'Actualizează parola contului',
                onTap: () => Get.to(() => const ChangePasswordPage()),
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.account_circle_outlined,
                iconColor: Colors.purple,
                title: 'Editează profilul',
                subtitle: 'Modifică informațiile personale',
                onTap: () => Get.to(() => EditProfilePage(controller: widget.controller)),
              ),
            ]),

            const SizedBox(height: 24),


            _buildSectionHeader('Preferințe', Icons.tune),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildSwitchItem(
                icon: Icons.notifications_outlined,
                iconColor: Colors.orange,
                title: 'Notificări',
                subtitle: 'Primește notificări push',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                  Get.snackbar(
                    'Notificări ${value ? 'activate' : 'dezactivate'}',
                    value ? 'Vei primi notificări' : 'Nu vei mai primi notificări',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
              ),
            ]),

            const SizedBox(height: 24),


            _buildSectionHeader('Despre', Icons.info_outline),
            const SizedBox(height: 12),
            _buildSettingsCard([
              _buildInfoItem(
                icon: Icons.phone_android,
                iconColor: Colors.green,
                title: 'Versiune aplicație',
                value: '1.0.0',
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.description_outlined,
                iconColor: Colors.teal,
                title: 'Termeni și condiții',
                subtitle: 'Citește termenii de utilizare',
                onTap: () => _showTermsDialog(),
              ),
              _buildDivider(),
              _buildNavigationItem(
                icon: Icons.privacy_tip_outlined,
                iconColor: Colors.cyan,
                title: 'Politica de confidențialitate',
                subtitle: 'Află cum îți protejăm datele',
                onTap: () => _showPrivacyDialog(),
              ),
            ]),

            const SizedBox(height: 32),


            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showLogoutConfirmation(),
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text(
                    'Deconectare',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),


            Center(
              child: Text(
                'School App © 2024',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!.withOpacity(0.5)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[600], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.blueAccent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.grey[800], height: 1),
    );
  }

  void _showLogoutConfirmation() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Confirmare deconectare',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Ești sigur că vrei să te deconectezi?',
          style: TextStyle(color: Colors.grey),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deconectare', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Termeni și condiții',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Prin utilizarea acestei aplicații, acceptați termenii și condițiile noastre de utilizare.\n\n'
            'Această aplicație este destinată gestionării activităților școlare și trebuie utilizată în conformitate cu regulamentele instituției.\n\n'
            'Ne rezervăm dreptul de a modifica acești termeni în orice moment.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Am înțeles'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Politica de confidențialitate',
          style: TextStyle(color: Colors.white),
        ),
        content: const SingleChildScrollView(
          child: Text(
            'Respectăm confidențialitatea datelor tale personale.\n\n'
            'Colectăm doar informațiile necesare pentru funcționarea aplicației.\n\n'
            'Datele tale sunt stocate în siguranță și nu sunt partajate cu terți fără consimțământul tău.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Am înțeles'),
          ),
        ],
      ),
    );
  }
}
