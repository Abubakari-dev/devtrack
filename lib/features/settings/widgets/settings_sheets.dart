import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/data_sync_service.dart';

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

  static void showLanguageDialog(BuildContext context, bool isDark, WidgetRef ref) {
    final currentLocale = ref.read(localeProvider);
    
    _showSheet(
      context,
      isDark,
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('preferences'), style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(context.tr('language'), style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 24),
            _languageOption(context, 'English (US)', '🇺🇸', currentLocale.languageCode == 'en', isDark, () {
              ref.read(localeProvider.notifier).state = const Locale('en');
              Navigator.pop(context);
            }),
            _languageOption(context, 'Swahili (TZ)', '🇹🇿', currentLocale.languageCode == 'sw', isDark, () {
              ref.read(localeProvider.notifier).state = const Locale('sw');
              Navigator.pop(context);
            }),
            _languageOption(context, 'French (FR)', '🇫🇷', currentLocale.languageCode == 'fr', isDark, () {
              ref.read(localeProvider.notifier).state = const Locale('fr');
              Navigator.pop(context);
            }),
            _languageOption(context, 'Arabic (SA)', '🇸🇦', currentLocale.languageCode == 'ar', isDark, () {
              ref.read(localeProvider.notifier).state = const Locale('ar');
              Navigator.pop(context);
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  static Widget _languageOption(BuildContext context, String name, String flag, bool selected, bool isDark, VoidCallback onTap) {
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
        onTap: onTap,
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
              Text(context.tr('security_hub'), style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(context.tr('update_password'), style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 8),
              Text(context.tr('update_password_desc'), style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 32),
              _buildModernTextField(isDark, currentPasswordController, context.tr('current_password'), Icons.lock_outline_rounded, AppColors.rose),
              const SizedBox(height: 16),
              _buildModernTextField(isDark, newPasswordController, context.tr('new_password'), Icons.security_rounded, AppColors.emerald),
              const SizedBox(height: 16),
              _buildModernTextField(isDark, confirmPasswordController, context.tr('repeat_new_password'), Icons.verified_user_rounded, AppColors.indigo),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(context.tr('update_security_key'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
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
            Text(context.tr('data_management'), style: const TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(context.tr('export_workspace'), style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text(context.tr('export_workspace_long_desc'), style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 32),
            _buildExportCard(context, isDark, Icons.picture_as_pdf_rounded, context.tr('project_report_pdf'), context.tr('project_report_pdf_desc'), AppColors.rose),
            const SizedBox(height: 16),
            _buildExportCard(context, isDark, Icons.table_chart_rounded, context.tr('data_sheet_excel'), context.tr('data_sheet_excel_desc'), AppColors.emerald),
            const SizedBox(height: 16),
            _buildExportCard(context, isDark, Icons.code_rounded, context.tr('backup_file_json'), context.tr('backup_file_json_desc'), AppColors.purple),
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('privacy_control').toUpperCase(), 
                      style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                    const SizedBox(height: 4),
                    Text(context.tr('privacy_security'), 
                      style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, fontSize: 24)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: AppColors.emerald, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSecurityInfoTile(
              icon: Icons.lock_rounded, 
              title: context.tr('e2e_encryption'), 
              desc: context.tr('e2e_encryption_desc'),
              color: AppColors.emerald,
              isDark: isDark,
            ),
            _buildSecurityInfoTile(
              icon: Icons.fingerprint_rounded, 
              title: context.tr('biometric_locking'), 
              desc: context.tr('biometric_locking_desc'),
              color: AppColors.blue,
              isDark: isDark,
            ),
            _buildSecurityInfoTile(
              icon: Icons.visibility_off_rounded, 
              title: context.tr('privacy_mode'), 
              desc: context.tr('privacy_mode_desc'),
              color: AppColors.indigo,
              isDark: isDark,
            ),
            _buildSecurityInfoTile(
              icon: Icons.history_rounded, 
              title: context.tr('data_retention'), 
              desc: context.tr('data_retention_desc'),
              color: AppColors.amber,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0D1117) : AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppColors.rose.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.warning_amber_rounded, color: AppColors.rose, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Text(context.tr('sensitive_actions').toUpperCase(), 
                        style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Deleting your account is permanent and will remove all project history, financial data, and personal information from our secure servers.',
                    style: TextStyle(
                      fontSize: 12, 
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showConfirmDeleteAccount(context, isDark);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.rose),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(context.tr('delete_account_data'), 
                        style: const TextStyle(color: AppColors.rose, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SyncSettingsSheet(isDark: isDark),
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
            Text(context.tr('support_hub'), style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            const SizedBox(height: 8),
            Text(context.tr('help_support'), style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildHelpAction(
                    context, isDark, Icons.mail_rounded, context.tr('direct_email_support'), context.tr('direct_email_desc'), AppColors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildHelpAction(
                    context, isDark, Icons.auto_awesome_rounded, context.tr('tutorial_guides'), context.tr('tutorial_guides_desc'), AppColors.indigo,
                  ),
                  const SizedBox(height: 12),
                  _buildHelpAction(
                    context, isDark, Icons.forum_rounded, context.tr('community_discord'), context.tr('community_discord_desc'), AppColors.purple,
                  ),
                  const SizedBox(height: 32),
                  Text(context.tr('frequent_questions'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                  const SizedBox(height: 16),
                  _buildFaqItem(isDark, context.tr('faq_1_q'), context.tr('faq_1_a')),
                  _buildFaqItem(isDark, context.tr('faq_2_q'), context.tr('faq_2_a')),
                  _buildFaqItem(isDark, context.tr('faq_3_q'), context.tr('faq_3_a')),
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
            Text('DevTrack', style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w900, fontSize: 32, letterSpacing: -1)),
            Text(context.tr('mission_control'), style: TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2.5)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: const Text('Version 1.0.4-PRO', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
            ),
            const SizedBox(height: 32),
            Text(
              context.tr('devtrack_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(height: 1.6, fontSize: 14, fontWeight: FontWeight.w500),
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
            Text(context.tr('made_with_love'), style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2)),
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
            Text(context.tr('end_session'), style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(context.tr('sign_out_warning'), 
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white54 : AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: Text(context.tr('stay_here'), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1))
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
                    child: Text(context.tr('sign_out').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1))
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

  static void showConfirmDeleteAccount(BuildContext context, bool isDark) {
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
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.rose, size: 40),
            ),
            const SizedBox(height: 24),
            Text('Permanent Deletion', style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, color: AppColors.rose)),
            const SizedBox(height: 12),
            const Text(
              'This action is irreversible. All your projects, financial records, and cloud backups will be permanently deleted from our servers.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context), 
                    child: Text(context.tr('cancel').toUpperCase(), style: TextStyle(color: isDark ? Colors.white38 : Colors.grey, fontWeight: FontWeight.w900, letterSpacing: 1))
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Implementation for actual cloud deletion would go here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deletion request sent to cloud...'),
                          backgroundColor: AppColors.rose,
                        ),
                      );
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.rose, 
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      minimumSize: const Size(0, 56),
                    ), 
                    child: const Text('DELETE ALL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1))
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

class _SyncSettingsSheet extends StatefulWidget {
  final bool isDark;
  const _SyncSettingsSheet({required this.isDark});

  @override
  State<_SyncSettingsSheet> createState() => _SyncSettingsSheetState();
}

class _SyncSettingsSheetState extends State<_SyncSettingsSheet> {
  bool _isSyncing = false;
  String _lastSyncText = 'Today at 10:45 AM • 4.2 MB uploaded';

  void _handleForceSync() async {
    setState(() => _isSyncing = true);
    try {
      await DataSyncService().syncAllData();
      if (mounted) {
        setState(() {
          _isSyncing = false;
          _lastSyncText = 'Just now • Sync completed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Synchronization successful'), backgroundColor: AppColors.emerald),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSyncing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppColors.rose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('cloud_infra').toUpperCase(),
                    style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text(context.tr('sync_engine'),
                    style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.w900, fontSize: 24)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_isSyncing ? Icons.sync_rounded : Icons.cloud_sync_rounded, color: AppColors.blue, size: 28),
              ).animate(onPlay: (controller) => _isSyncing ? controller.repeat() : controller.stop())
               .rotate(duration: 1.seconds),
            ],
          ),
          const SizedBox(height: 32),
          _buildSyncControl(
            title: context.tr('auto_sync_workspace'),
            subtitle: context.tr('auto_sync_desc'),
            icon: Icons.sync_rounded,
            value: true,
            isDark: widget.isDark,
            onChanged: (v) {},
          ),
          const SizedBox(height: 16),
          _buildSyncControl(
            title: context.tr('sync_wifi_only'),
            subtitle: context.tr('sync_wifi_desc'),
            icon: Icons.wifi_rounded,
            value: false,
            isDark: widget.isDark,
            onChanged: (v) {},
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.isDark ? const Color(0xFF0D1117) : AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emerald.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_isSyncing ? Icons.hourglass_empty_rounded : Icons.check_circle_rounded, color: AppColors.emerald, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('last_sync_status'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(_lastSyncText,
                            style: const TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSyncing ? null : _handleForceSync,
                    icon: _isSyncing 
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_isSyncing ? 'SYNCING...' : context.tr('force_sync').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      disabledBackgroundColor: AppColors.blue.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSyncControl({required String title, required String subtitle, required IconData icon, required bool value, required bool isDark, required Function(bool) onChanged}) {
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
}
