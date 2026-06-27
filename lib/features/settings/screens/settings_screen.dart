import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/services/project_service.dart';
import '../../projects/models/models.dart';
import '../widgets/settings_sheets.dart';
import '../../finance/screens/expenses/all_expenses_screen.dart';
import '../../../core/services/security_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return name.isNotEmpty ? name.substring(0, name.length > 1 ? 2 : 1).toUpperCase() : '??';
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectService = ProjectService(uid: user?.uid ?? '');
    final currentLocale = ref.watch(localeProvider);
    final languageName = currentLocale.languageCode == 'en' ? 'English' : 
                         currentLocale.languageCode == 'sw' ? 'Swahili' : 
                         currentLocale.languageCode == 'fr' ? 'French' : 'Arabic';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),
                StreamBuilder<DocumentSnapshot?>(
                  stream: user != null 
                      ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
                      : Stream.value(null),
                  builder: (context, userSnapshot) {
                    String fullName = 'Developer';
                    if (userSnapshot.hasData && userSnapshot.data?.data() != null) {
                      final data = userSnapshot.data!.data() as Map<String, dynamic>;
                      fullName = data['name'] ?? user?.displayName ?? 'Developer';
                    } else if (user?.displayName != null) {
                      fullName = user!.displayName!;
                    }

                    return StreamBuilder<List<Project>>(
                      stream: projectService.getProjectsStream(),
                      builder: (context, snapshot) {
                        final projects = snapshot.data ?? [];
                        final activeCount = projects.where((p) => p.status == ProjectStatus.active).length;
                        final doneCount = projects.where((p) => p.status == ProjectStatus.completed).length;
                        
                        double avgQuality = 0;
                        if (projects.isNotEmpty) {
                          final totalProgress = projects.fold<double>(0, (sum, p) => sum + p.progressPercent);
                          avgQuality = (totalProgress / projects.length) * 100;
                        }

                        return _buildProfileSection(context, user, fullName, isDark, activeCount, doneCount, avgQuality);
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                _buildSectionHeader(context, context.tr('preferences'), isDark),
                _buildSettingsGroup([
                  _buildSettingItem(
                    context: context,
                    icon: Icons.auto_awesome_rounded,
                    title: context.tr('app_features'),
                    subtitle: 'Debts, Budgets & More',
                    color: AppColors.purple,
                    isDark: isDark,
                    onTap: () => context.push('/features'),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.notifications_active_rounded,
                    title: context.tr('notifications'),
                    subtitle: context.tr('notifications_desc'),
                    color: AppColors.indigo,
                    isDark: isDark,
                    onTap: () => context.push('/notifications'),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    title: isDark ? context.tr('light_mode') : context.tr('dark_mode'),
                    subtitle: isDark ? context.tr('appearance_light_desc') : context.tr('appearance_dark_desc'),
                    color: AppColors.emerald,
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (v) {
                        ThemeProvider.themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeColor: AppColors.emerald,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.language_rounded,
                    title: context.tr('language'),
                    subtitle: languageName,
                    color: AppColors.blue,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showLanguageDialog(context, isDark, ref),
                  ),
                ], isDark),

                const SizedBox(height: 24),
                _buildSectionHeader(context, context.tr('security_hub'), isDark),
                _buildSettingsGroup([
                  _buildSettingItem(
                    context: context,
                    icon: Icons.lock_rounded,
                    title: context.tr('access_credentials'),
                    subtitle: context.tr('access_credentials_desc'),
                    color: AppColors.rose,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showChangePasswordDialog(context, isDark),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric Lock',
                    subtitle: 'Secure Finance with Fingerprint',
                    color: AppColors.purple,
                    isDark: isDark,
                    trailing: FutureBuilder<bool>(
                      future: SecurityService.instance.isBiometricEnabled,
                      builder: (context, snapshot) {
                        return Switch.adaptive(
                          value: snapshot.data ?? false,
                          onChanged: (v) async {
                            if (v) {
                              final auth = await SecurityService.instance.authenticate(
                                reason: 'Confirm your identity to enable biometric lock',
                              );
                              if (auth) {
                                await SecurityService.instance.setBiometricEnabled(true);
                                setState(() {});
                              }
                            } else {
                              await SecurityService.instance.setBiometricEnabled(false);
                              setState(() {});
                            }
                          },
                          activeColor: AppColors.purple,
                        );
                      },
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.shield_rounded,
                    title: context.tr('privacy_security'),
                    subtitle: context.tr('privacy_security_desc'),
                    color: AppColors.amber,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showPrivacyInfo(context, isDark),
                  ),
                ], isDark),

                const SizedBox(height: 24),
                _buildSectionHeader(context, context.tr('workflow_data'), isDark),
                _buildSettingsGroup([


                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.file_download_rounded,
                    title: context.tr('export_workspace'),
                    subtitle: context.tr('export_workspace_desc'),
                    color: AppColors.indigo,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showExportOptions(context, isDark),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.sync_rounded,
                    title: context.tr('cloud_sync'),
                    subtitle: context.tr('cloud_sync_desc'),
                    color: AppColors.blue,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showSyncSettings(context, isDark),
                  ),
                ], isDark),

                const SizedBox(height: 24),
                _buildSectionHeader(context, context.tr('resources'), isDark),
                _buildSettingsGroup([
                  _buildSettingItem(
                    context: context,
                    icon: Icons.help_rounded,
                    title: context.tr('support_center'),
                    subtitle: context.tr('support_center_desc'),
                    color: AppColors.orange,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showHelpDialog(context, isDark),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    context: context,
                    icon: Icons.rocket_launch_rounded,
                    title: context.tr('about_devtrack'),
                    subtitle: context.tr('about_devtrack_desc'),
                    color: AppColors.indigo,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showAboutDialog(context, isDark),
                  ),
                ], isDark),

                const SizedBox(height: 32),
                _buildLogoutButton(isDark),
                const SizedBox(height: 48),
                _buildFooter(isDark),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      toolbarHeight: 80,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Text(
        context.tr('settings'),
        style: AppTextStyles.h1.copyWith(
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, User? user, String fullName, bool isDark, int active, int done, double quality) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  gradient: AppColors.indigoGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: AppColors.indigo.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(fullName),
                    style: AppTextStyles.semiBold.copyWith(color: Colors.white, fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppTextStyles.h2.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user?.email ?? 'developer@devtrack.io',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.indigo, 
                          letterSpacing: 0,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildStatsRow(context, isDark, active, done, quality),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsRow(BuildContext context, bool isDark, int active, int done, double quality) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildProfileStat(context, active.toString(), context.tr('active'), isDark),
          _buildStatDivider(isDark),
          _buildProfileStat(context, done.toString(), context.tr('done_label'), isDark),
          _buildStatDivider(isDark),
          _buildProfileStat(context, '${quality.toInt()}%', context.tr('efficiency'), isDark),
        ],
      ),
    );
  }

  Widget _buildProfileStat(BuildContext context, String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value, 
          style: AppTextStyles.h3.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(), 
          style: AppTextStyles.labelSmall.copyWith(
            color: isDark ? Colors.white38 : AppColors.textMuted, 
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(width: 1.5, height: 24, color: isDark ? const Color(0xFF30363D) : AppColors.borderLight);
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: isDark ? Colors.white38 : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: Column(children: children),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSettingItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title, 
                      style: AppTextStyles.subtitle.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle, 
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? Colors.white38 : AppColors.textSecondary, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(Icons.chevron_right_rounded, size: 22, color: isDark ? Colors.white10 : Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 72, endIndent: 20, color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.4));
  }

  Widget _buildLogoutButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () => SettingsSheets.showConfirmSignOut(context, isDark, () async {
          await _auth.signOut();
          if (mounted) context.go('/login');
        }),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.rose.withValues(alpha: 0.4), width: 1.5),
          backgroundColor: isDark ? AppColors.rose.withValues(alpha: 0.05) : AppColors.rose.withValues(alpha: 0.02),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 22, color: AppColors.rose),
            const SizedBox(width: 12),
            Text(
              context.tr('sign_out').toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.rose, 
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle)),
            const SizedBox(width: 12),
            Text(
              'DEVTRACK INTELLIGENCE',
              style: AppTextStyles.labelSmall.copyWith(
                color: isDark ? Colors.white24 : AppColors.textMuted, 
                fontSize: 9,
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.indigo, shape: BoxShape.circle)),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'v1.0.4-PRO • SECURE BUILD 2026',
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 10, 
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white10 : AppColors.textMuted.withValues(alpha: 0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
