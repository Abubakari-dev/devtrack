import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class SettingsSheets {
  static void _showSheet(BuildContext context, bool isDark, Widget child, {double? heightFactor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: heightFactor != null ? MediaQuery.of(context).size.height * heightFactor : null,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  static void showLanguageDialog(BuildContext context, bool isDark) {
    _showSheet(
      context,
      isDark,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PREFERENCES', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('App Language', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 24),
            _languageOption(context, 'English (US)', '🇺🇸', true, isDark),
            _languageOption(context, 'Swahili (TZ)', '🇹🇿', false, isDark),
            _languageOption(context, 'French (FR)', '🇫🇷', false, isDark),
            _languageOption(context, 'Arabic (SA)', '🇸🇦', false, isDark),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _languageOption(BuildContext context, String name, String flag, bool selected, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected ? AppColors.blue.withOpacity(0.08) : (isDark ? const Color(0xFF0D1117) : AppColors.surface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.blue.withOpacity(0.4) : (isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
          width: selected ? 2 : 1.5,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Text(flag, style: const TextStyle(fontSize: 26)),
        title: Text(name, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: selected ? FontWeight.w800 : FontWeight.w600, fontSize: 15)),
        trailing: selected 
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppColors.blue, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ) 
          : null,
        onTap: () => Navigator.pop(context),
      ),
    );
  }

  static void showChangePasswordDialog(BuildContext context, bool isDark) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161B22) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              const Text('SECURITY CENTER', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text('Update Password', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              Text('Ensure your account stays secure with a strong password.', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 32),
              _buildModernTextField(isDark, currentPasswordController, 'Current Password', Icons.lock_outline_rounded, AppColors.rose),
              const SizedBox(height: 16),
              _buildModernTextField(isDark, newPasswordController, 'New Password', Icons.security_rounded, AppColors.emerald),
              const SizedBox(height: 16),
              _buildModernTextField(isDark, confirmPasswordController, 'Repeat New Password', Icons.verified_user_rounded, AppColors.indigo),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Update Security Key', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildModernTextField(bool isDark, TextEditingController controller, String label, IconData icon, Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        obscureText: true,
        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: accentColor, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  static void showExportOptions(BuildContext context, bool isDark) {
    _showSheet(
      context,
      isDark,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DATA MANAGEMENT', style: TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Export Workspace', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text('Take your data with you in high-quality formats.', style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),
            _buildExportCard(context, isDark, Icons.picture_as_pdf_rounded, 'Project Report (PDF)', 'Detailed summary with charts & progress', AppColors.rose),
            const SizedBox(height: 16),
            _buildExportCard(context, isDark, Icons.table_chart_rounded, 'Data Sheet (Excel)', 'Raw project data for financial analysis', AppColors.emerald),
            const SizedBox(height: 16),
            _buildExportCard(context, isDark, Icons.code_rounded, 'Backup File (JSON)', 'Complete workspace backup for restoration', AppColors.purple),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildExportCard(BuildContext context, bool isDark, IconData icon, String title, String subtitle, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                  child: Icon(icon, color: color, size: 26),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white24 : Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1);
  }

  static void showPrivacyInfo(BuildContext context, bool isDark) {
    _showSheet(
      context,
      isDark,
      heightFactor: 0.8,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PRIVACY CONTROL', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Privacy & Security', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildSecurityInfoTile(
                    icon: Icons.lock_rounded, 
                    title: 'End-to-End Encryption', 
                    desc: 'Your project details and financial data are encrypted before being stored in the cloud.',
                    color: AppColors.emerald,
                    isDark: isDark,
                  ),
                  _buildSecurityInfoTile(
                    icon: Icons.fingerprint_rounded, 
                    title: 'Biometric Locking', 
                    desc: 'Enable fingerprint or face recognition to access sensitive workspace areas.',
                    color: AppColors.blue,
                    isDark: isDark,
                  ),
                  _buildSecurityInfoTile(
                    icon: Icons.visibility_off_rounded, 
                    title: 'Privacy Mode', 
                    desc: 'Hide sensitive amounts and client names on the main dashboard with one tap.',
                    color: AppColors.indigo,
                    isDark: isDark,
                  ),
                  _buildSecurityInfoTile(
                    icon: Icons.history_rounded, 
                    title: 'Data Retention', 
                    desc: 'Deleted projects are kept for 30 days in the trash before being permanently erased.',
                    color: AppColors.amber,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.rose.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.rose.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 20),
                            SizedBox(width: 8),
                            Text('Sensitive Actions', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w900, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: const Text('Delete Account & All Data', style: TextStyle(color: AppColors.rose, fontWeight: FontWeight.w700, decoration: TextDecoration.underline)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  static Widget _buildSecurityInfoTile({required IconData icon, required String title, required String desc, required Color color, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 13, height: 1.5, color: isDark ? Colors.white54 : AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1);
  }

  static void showSyncSettings(BuildContext context, bool isDark) {
    _showSheet(
      context,
      isDark,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CLOUD INFRASTRUCTURE', style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Sync Engine', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            _buildSyncControl(
              title: 'Auto-Sync Workspace',
              subtitle: 'Keep all devices updated instantly',
              icon: Icons.sync_rounded,
              value: true,
              isDark: isDark,
              onChanged: (v) {},
            ),
            const SizedBox(height: 16),
            _buildSyncControl(
              title: 'Sync via WiFi Only',
              subtitle: 'Save mobile data for large file syncs',
              icon: Icons.wifi_rounded,
              value: false,
              isDark: isDark,
              onChanged: (v) {},
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1117) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last Sync Status', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('Today at 10:45 AM • 4.2 MB uploaded', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 11)),
                    ],
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {}, 
                    icon: const Icon(Icons.refresh_rounded, size: 18), 
                    label: const Text('Force Sync', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildSyncControl({required String title, required String subtitle, required IconData icon, required bool value, required bool isDark, required Function(bool) onChanged}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.blue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : AppColors.textSecondary)),
        secondary: Icon(icon, color: AppColors.blue),
      ),
    );
  }

  static void showHelpDialog(BuildContext context, bool isDark) {
    _showSheet(
      context,
      isDark,
      heightFactor: 0.75,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SUPPORT HUB', style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text('Help & Support', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildHelpAction(
                    context, isDark, Icons.mail_rounded, 'Direct Email Support', 'Response within 24 hours', AppColors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildHelpAction(
                    context, isDark, Icons.auto_awesome_rounded, 'Tutorial Guides', 'Master DevTrack workflow', AppColors.indigo,
                  ),
                  const SizedBox(height: 12),
                  _buildHelpAction(
                    context, isDark, Icons.forum_rounded, 'Community Discord', 'Chat with other developers', AppColors.purple,
                  ),
                  const SizedBox(height: 32),
                  const Text('FREQUENT QUESTIONS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  _buildFaqItem(isDark, 'How do I backup my projects?', 'Go to Data & Operations > Export Data to download a full JSON backup of your workspace.'),
                  _buildFaqItem(isDark, 'Can I collaborate with others?', 'Yes! Open any project and use the "Members" icon to invite team members via email.'),
                  _buildFaqItem(isDark, 'Is my financial data safe?', 'Absolutely. We use industry-standard encryption and never share your data with third parties.'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  static Widget _buildHelpAction(BuildContext context, bool isDark, IconData icon, String title, String subtitle, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.open_in_new_rounded, size: 16),
        onTap: () {},
      ),
    );
  }

  static Widget _buildFaqItem(bool isDark, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : AppColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }

  static void showAboutDialog(BuildContext context, bool isDark) {
    _showSheet(
      context,
      isDark,
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.indigoGradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: AppColors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: const Icon(Icons.rocket_launch_rounded, size: 54, color: Colors.white),
            ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text('DevTrack', style: AppTextStyles.h1(context).copyWith(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
            Text('MISSION CONTROL FOR DEVELOPERS', style: TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: const Text('Version 1.0.4-PRO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
            const SizedBox(height: 32),
            const Text(
              'A powerful, simple, and elegant workspace designed to help developers track missions, manage roadmaps, and optimize workflow.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialIcon(Icons.language_rounded),
                const SizedBox(width: 24),
                _socialIcon(Icons.code_rounded),
                const SizedBox(width: 24),
                _socialIcon(Icons.alternate_email_rounded),
              ],
            ),
            const SizedBox(height: 40),
            Text('MADE WITH ❤️ BY ABUU', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _socialIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.indigo.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.indigo, size: 20),
    );
  }

  static void showConfirmSignOut(BuildContext context, bool isDark, VoidCallback onConfirm) {
    _showSheet(
      context,
      isDark,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: AppColors.rose, size: 40),
            ),
            const SizedBox(height: 24),
            Text('End Session?', style: AppTextStyles.h2(context).copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text('You will need to re-authenticate to access your missions.', 
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: Text('STAY HERE', style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1))
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rose, 
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(0, 56),
                    ), 
                    child: const Text('SIGN OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1))
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
