import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../welcome_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _selectedLang = 'ro';
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    final locale = Get.locale;
    _selectedLang = (locale?.languageCode ?? 'ro');
    _darkModeEnabled = Get.isDarkMode;
  }

  void _changeLanguage(String code) async {
    setState(() => _selectedLang = code);

    await SecureStorageService.saveLanguage(code);

    Get.updateLocale(Locale(code));

    Get.snackbar(
      'success'.tr,
      'language_changed'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1C20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'logout_confirm_title'.tr,
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'logout_confirm_message'.tr,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('logout'.tr),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoggingOut = true);
      try {
        await AuthService().logout();
        await CacheService.clearAll();
        Get.offAll(() => const WelcomePage());
      } catch (e) {
        setState(() => _isLoggingOut = false);
        Get.snackbar(
          'Error',
          'logout_error'.tr,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  Future<void> _clearCache() async {
    await CacheService.clearAll();
    Get.snackbar(
      'success'.tr,
      'cache_cleared'.tr,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0D),
      appBar: AppBar(
        title: Text('settings_title'.tr),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: _isLoggingOut
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('settings_notifications'.tr),
                _buildSettingsCard([
                  _buildSwitchTile(
                    icon: Icons.notifications,
                    iconColor: Colors.orange,
                    title: 'settings_push_notifications'.tr,
                    subtitle: 'settings_push_notifications_desc'.tr,
                    value: _notificationsEnabled,
                    onChanged: (v) => setState(() => _notificationsEnabled = v),
                  ),
                ]),

                const SizedBox(height: 24),


                _buildSectionHeader('settings_language'.tr),
                _buildSettingsCard([
                  _buildLanguageTile('ro', 'language_ro'.tr, '🇷🇴'),
                  const Divider(color: Colors.white10, height: 1),
                  _buildLanguageTile('en', 'language_en'.tr, '🇬🇧'),
                  const Divider(color: Colors.white10, height: 1),
                  _buildLanguageTile('ru', 'language_ru'.tr, '🇷🇺'),
                ]),

                const SizedBox(height: 24),


                _buildSectionHeader('settings_data'.tr),
                _buildSettingsCard([
                  _buildActionTile(
                    icon: Icons.cached,
                    iconColor: Colors.blue,
                    title: 'settings_clear_cache'.tr,
                    subtitle: 'settings_clear_cache_desc'.tr,
                    onTap: _clearCache,
                  ),
                ]),

                const SizedBox(height: 24),


                _buildSectionHeader('settings_account'.tr),
                _buildSettingsCard([
                  _buildActionTile(
                    icon: Icons.logout,
                    iconColor: Colors.red,
                    title: 'logout'.tr,
                    subtitle: 'settings_logout_desc'.tr,
                    onTap: _logout,
                    isDestructive: true,
                  ),
                ]),

                const SizedBox(height: 32),


                Center(
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1C20), Color(0xFF111827)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: iconColor,
      ),
    );
  }

  Widget _buildLanguageTile(String code, String name, String flag) {
    final isSelected = _selectedLang == code;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name, style: const TextStyle(color: Colors.white)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.circle_outlined, color: Colors.white24),
      onTap: () => _changeLanguage(code),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.white),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }
}
