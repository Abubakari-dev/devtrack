import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/project_service.dart';
import '../../projects/models/project_model.dart';
import '../widgets/settings_sheets.dart';
import '../../finance/screens/all_expenses_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.surface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark),
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

                        return _buildProfileSection(user, fullName, isDark, activeCount, doneCount, avgQuality);
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                _buildSectionHeader('PREFERENCES', isDark),
                _buildSettingsGroup([
                  _buildSettingItem(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifications',
                    subtitle: 'Banners, sounds & alerts',
                    color: AppColors.indigo,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, '/notification-settings'),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    title: isDark ? 'Light Appearance' : 'Dark Appearance',
                    subtitle: isDark ? 'Switch to clear theme' : 'Switch to stealth theme',
                    color: AppColors.emerald,
                    isDark: isDark,
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (v) {
                        AppTheme.themeNotifier.value = v ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeColor: AppColors.emerald,
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    icon: Icons.language_rounded,
                    title: 'Region & Language',
                    subtitle: 'English (US)',
                    color: AppColors.blue,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showLanguageDialog(context, isDark),
                  ),
                ], isDark),

                const SizedBox(height: 24),
                _buildSectionHeader('SECURITY HUB', isDark),
                _buildSettingsGroup([
                  _buildSettingItem(
                    icon: Icons.lock_rounded,
                    title: 'Access Credentials',
                    subtitle: 'Manage account password',
                    color: AppColors.rose,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showChangePasswordDialog(context, isDark),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    icon: Icons.shield_rounded,
                    title: 'Privacy & Security',
                    subtitle: 'Data encryption & visibility',
                    color: AppColors.amber,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showPrivacyInfo(context, isDark),
                  ),
                ], isDark),

                const SizedBox(height: 24),
                _buildSectionHeader('WORKFLOW DATA', isDark),
                _buildSettingsGroup([
                  _buildSettingItem(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Finance',
                    subtitle: 'Revenue, expenses & budgets',
                    color: AppColors.emerald,
                    isDark: isDark,
                    onTap: () => Navigator.pushNamed(context, '/finance'),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Expenses & Savings',
                    subtitle: 'Track spending & savings goals',
                    color: AppColors.amber,
                    isDark: isDark,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllExpensesScreen()),
                    ),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    icon: Icons.file_download_rounded,
                    title: 'Export Workspace',
                    subtitle: 'Reports, backups & data sheets',
                    color: AppColors.indigo,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showExportOptions(context, isDark),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    icon: Icons.sync_rounded,
                    title: 'Cloud Synchronization',
                    subtitle: 'Real-time engine settings',
                    color: AppColors.blue,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showSyncSettings(context, isDark),
                  ),
                ], isDark),

                const SizedBox(height: 24),
                _buildSectionHeader('RESOURCES', isDark),
                _buildSettingsGroup([
                  _buildSettingItem(
                    icon: Icons.help_rounded,
                    title: 'Support Center',
                    subtitle: 'FAQ, help & contact info',
                    color: AppColors.orange,
                    isDark: isDark,
                    onTap: () => SettingsSheets.showHelpDialog(context, isDark),
                  ),
                  _buildDivider(isDark),
                  _buildSettingItem(
                    icon: Icons.rocket_launch_rounded,
                    title: 'About DevTrack',
                    subtitle: 'Mission, version & credits',
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

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar(
      expandedHeight: 0,
      toolbarHeight: 80,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.surface,
      elevation: 0,
      centerTitle: false,
      title: Text(
        'Workspace Settings',
        style: AppTextStyles.h1(context).copyWith(
          fontWeight: FontWeight.w900, 
          fontSize: 28,
          letterSpacing: -1.0,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  Widget _buildProfileSection(User? user, String fullName, bool isDark, int active, int done, double quality) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))
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
                    BoxShadow(color: AppColors.indigo.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))
                  ],
                ),
                child: Center(
                  child: Text(
                    _getInitials(fullName),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
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
                      style: AppTextStyles.titleLarge(context).copyWith(
                        fontWeight: FontWeight.w900, 
                        fontSize: 22,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        user?.email ?? 'developer@devtrack.io',
                        style: TextStyle(
                          color: AppColors.indigo, 
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildStatsRow(isDark, active, done, quality),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatsRow(bool isDark, int active, int done, double quality) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1117) : AppColors.surface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildProfileStat(active.toString(), 'Active', isDark),
          _buildStatDivider(isDark),
          _buildProfileStat(done.toString(), 'Done', isDark),
          _buildStatDivider(isDark),
          _buildProfileStat('${quality.toInt()}%', 'Efficiency', isDark),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.w900, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(), 
          style: TextStyle(
            fontSize: 9, 
            color: isDark ? Colors.white38 : AppColors.textMuted, 
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(width: 1.5, height: 24, color: isDark ? const Color(0xFF30363D) : AppColors.borderLight);
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white38 : AppColors.textMuted,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.5,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
      ),
      child: Column(children: children),
    ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildSettingItem({
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
                  color: color.withOpacity(0.12),
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
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1F2328),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle, 
                        style: TextStyle(
                          fontSize: 12,
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
    return Divider(height: 1, indent: 72, endIndent: 20, color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.4));
  }

  Widget _buildLogoutButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: OutlinedButton(
        onPressed: () => SettingsSheets.showConfirmSignOut(context, isDark, () async {
          await _auth.signOut();
          if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        }),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.rose.withOpacity(0.4), width: 1.5),
          backgroundColor: isDark ? AppColors.rose.withOpacity(0.05) : AppColors.rose.withOpacity(0.02),
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
            const Text(
              'TERMINATE SESSION',
              style: TextStyle(
                color: AppColors.rose, 
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
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
              style: TextStyle(
                color: isDark ? Colors.white24 : AppColors.textMuted, 
                letterSpacing: 3.5,
                fontWeight: FontWeight.w900,
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
          style: TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white10 : AppColors.textMuted.withOpacity(0.5),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
