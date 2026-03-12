import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/project_service.dart';
import '../../../core/routes/app_router.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../projects/models/models.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/screens/projects_screen.dart';

// ─────────────────────────────────────────────
//  ROOT DASHBOARD
// ─────────────────────────────────────────────
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _navIndex = 0;

  void setNavIndex(int index) {
    if (index != _navIndex) {
      setState(() => _navIndex = index);
    }
  }

  final List<Widget> _screens = const [
    HomeTab(),
    ProjectsScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return PopScope(
      canPop: false, // Prevent app from closing immediately
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        // If not on Home tab, go back to Home tab first
        if (_navIndex != 0) {
          setState(() => _navIndex = 0);
        } else {
          // If already on Home tab, show a system dialog or just do nothing
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: IndexedStack(
          index: _navIndex,
          children: _screens,
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _navIndex,
          onTap: setNavIndex,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  HOME TAB
// ─────────────────────────────────────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: const _Fab(),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot?>(
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

            final projectService = ProjectService(uid: user?.uid ?? '');

            return StreamBuilder<List<Project>>(
              stream: projectService.getProjectsStream(),
              builder: (context, snapshot) {
                // Handle errors
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unable to load projects',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white60 : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please check your connection',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white38 : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final projects = snapshot.data ?? [];
                
                // Display all projects EXCEPT completed ones
                final ongoingProjects = projects.where((p) => 
                  p.status != ProjectStatus.completed
                ).toList();

                final completedCount = projects.where((p) => p.status == ProjectStatus.completed).length;
                final overdueCount = projects.where((p) => p.status == ProjectStatus.overdue).length;
                
                final score = _calculateScore(projects, ongoingProjects, overdueCount, completedCount);

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: _HeaderCard(fullName: fullName),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _OverviewCard(
                          score: score,
                          ongoing: ongoingProjects.length,
                          completed: completedCount,
                          overdue: overdueCount,
                          total: projects.length,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 36)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SectionHeader(
                          title: 'Ongoing Work',
                          onSeeAll: () => context.findAncestorStateOfType<_DashboardScreenState>()?.setNavIndex(1),
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 18)),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: ongoingProjects.isEmpty 
                        ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _ProjectCard(project: ongoingProjects[i])
                                  .animate()
                                  .fadeIn(duration: 400.ms, delay: (i * 100).ms)
                                  .slideX(begin: 0.1, end: 0),
                              childCount: ongoingProjects.length,
                            ),
                          ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.rocket_launch_rounded, size: 48, color: isDark ? Colors.white24 : AppColors.border),
            ),
            const SizedBox(height: 24),
            Text(
              'No active missions', 
              style: AppTextStyles.h2(context).copyWith(
                color: isDark ? Colors.white : Colors.black, 
                fontWeight: FontWeight.w900
              )
            ),
            const SizedBox(height: 8),
            Text(
              'Everything is clear. Time to start something new!', 
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context).copyWith(
                color: isDark ? Colors.white38 : AppColors.textMuted
              )
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }

  int _calculateScore(List<Project> all, List<Project> ongoing, int overdue, int done) {
    if (all.isEmpty) return 0;
    double compRate = (done / all.length) * 40;
    double timeRate = ((all.length - overdue) / all.length) * 40;
    double progRate = 0;
    if (ongoing.isNotEmpty) {
      progRate = (ongoing.fold<double>(0, (s, p) => s + p.progressPercent) / ongoing.length) * 20 * 100;
    }
    return (compRate + timeRate + (progRate / 100)).toInt().clamp(0, 100);
  }
}

// ─────────────────────────────────────────────
//  HEADER CARD
// ─────────────────────────────────────────────
class _HeaderCard extends StatelessWidget {
  final String fullName;
  const _HeaderCard({required this.fullName});

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0].toUpperCase()}${parts[1][0].toUpperCase()}';
    }
    return name.isNotEmpty ? name.substring(0, name.length > 1 ? 2 : 1).toUpperCase() : '??';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = fullName.split(' ')[0];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.indigoGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withOpacity(0.25), 
            blurRadius: 24, 
            offset: const Offset(0, 12)
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Center(
              child: Text(
                _getInitials(fullName), 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,', 
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500)
                ),
                Text(
                  '$firstName!', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -0.5)
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot?>(
            stream: FirebaseAuth.instance.currentUser != null
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .snapshots()
                : Stream.value(null),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        unreadCount > 0 
                          ? Icons.notifications_active_rounded 
                          : Icons.notifications_none_rounded, 
                        color: Colors.white, 
                        size: 24,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          decoration: BoxDecoration(
                            color: AppColors.rose,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.rose.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                height: 1,
                              ),
                            ),
                          ),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .scale(
                            duration: 1000.ms,
                            begin: const Offset(1.0, 1.0),
                            end: const Offset(1.1, 1.1),
                            curve: Curves.easeInOut,
                          )
                          .then()
                          .scale(
                            duration: 1000.ms,
                            begin: const Offset(1.1, 1.1),
                            end: const Offset(1.0, 1.0),
                            curve: Curves.easeInOut,
                          ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1, end: 0);
  }
}

// ─────────────────────────────────────────────
//  OVERVIEW CARD
// ─────────────────────────────────────────────
class _OverviewCard extends StatelessWidget {
  final int score, ongoing, completed, overdue, total;
  const _OverviewCard({
    required this.score, 
    required this.ongoing, 
    required this.completed, 
    required this.overdue, 
    required this.total
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PERFORMANCE SCORE', 
                    style: TextStyle(
                      color: isDark ? Colors.white38 : AppColors.textMuted, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w900, 
                      letterSpacing: 1.2
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Stability Level', 
                    style: AppTextStyles.h3(context).copyWith(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w800)
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (score > 75 ? AppColors.green : score > 40 ? AppColors.amber : AppColors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score%', 
                  style: TextStyle(
                    color: score > 75 ? AppColors.green : score > 40 ? AppColors.amber : AppColors.red, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 18
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'Ongoing', value: '$ongoing', color: AppColors.indigo),
              _Stat(label: 'Done', value: '$completed', color: AppColors.green),
              _Stat(label: 'Alerts', value: '$overdue', color: AppColors.red),
              _Stat(label: 'Total', value: '$total', color: isDark ? Colors.white : Colors.black),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 100.ms).slideY(begin: 0.1, end: 0);
  }
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(
          value, 
          style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5)
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(), 
          style: TextStyle(
            color: isDark ? Colors.white38 : AppColors.textMuted, 
            fontSize: 9, 
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5
          )
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  SECTION HEADER
// ─────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title, 
          style: AppTextStyles.h2(context).copyWith(
            color: isDark ? Colors.white : Colors.black, 
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5
          )
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: const Text(
            'See all projects', 
            style: TextStyle(
              color: AppColors.indigo, 
              fontWeight: FontWeight.w800, 
              fontSize: 13
            )
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  PROJECT CARD
// ─────────────────────────────────────────────
class _ProjectCard extends StatelessWidget {
  final Project project;
  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = project.statusColor;
    final progress = project.progressPercent.clamp(0.0, 1.0);
    
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(
            projectId: project.id,
            initialProject: project,
          ),
        ),
      ),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161B22) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5)),
          boxShadow: isDark ? [] : [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: project.projectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(project.projectEmoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name, 
                        style: TextStyle(
                          fontWeight: FontWeight.w900, 
                          fontSize: 16, 
                          color: isDark ? Colors.white : Colors.black, 
                          letterSpacing: -0.2
                        )
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.categoryLabel, 
                        style: TextStyle(
                          color: isDark ? Colors.white38 : AppColors.textSecondary, 
                          fontSize: 12, 
                          fontWeight: FontWeight.w500
                        )
                      ),
                    ],
                  )
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: statusColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    project.statusLabel.toUpperCase(), 
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress', 
                  style: TextStyle(color: isDark ? Colors.white54 : AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700)
                ),
                Text(
                  '${(progress * 100).toInt()}%', 
                  style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 12, fontWeight: FontWeight.w900)
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.surface,
                valueColor: AlwaysStoppedAnimation(project.projectColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  FAB
// ─────────────────────────────────────────────
class _Fab extends StatelessWidget {
  const _Fab();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withOpacity(0.3), 
            blurRadius: 15, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'dashboard_fab',
        onPressed: () => Navigator.of(context).pushNamed(AppRoutes.addEditProject),
        backgroundColor: AppColors.indigo,
        elevation: 0,
        label: const Text('NEW PROJECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2)),
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    ).animate().fadeIn(duration: 800.ms, delay: 400.ms).scale(begin: const Offset(0.5, 0.5));
  }
}

// ─────────────────────────────────────────────
//  BOTTOM NAV
// ─────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withOpacity(0.5), 
            width: 1
          )
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.indigo,
        unselectedItemColor: isDark ? Colors.white24 : Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder_copy_rounded), label: 'Projects'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_suggest_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}
