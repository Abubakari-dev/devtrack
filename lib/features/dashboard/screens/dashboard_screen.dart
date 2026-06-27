import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../finance/providers/finance_providers.dart';
import '../../finance/domain/models/finance_summary.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../projects/providers/projects_providers.dart';
import '../../projects/models/models.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/dev_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const _DashboardAppBar(),
          
          Consumer(
            builder: (context, ref, child) {
              final projectsState = ref.watch(projectsNotifierProvider);
              final activeProjects = projectsState.allProjects.where((p) => p.status == ProjectStatus.active).toList();
              final completedCount = projectsState.allProjects.where((p) => p.status == ProjectStatus.completed).length;
              final overdueCount = projectsState.allProjects.where((p) => p.status == ProjectStatus.overdue).length;
              final financeAsync = ref.watch(financeSummaryProvider);

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _DashboardStatusCards(
                    activeCount: activeProjects.length,
                    completedCount: completedCount,
                    overdueCount: overdueCount,
                    isDark: isDark,
                  ),
                ),
              );
            },
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: DevSectionHeader(
                title: context.tr('active_projects'),
                overline: context.tr('tracking_progress'),
                trailing: TextButton(
                  onPressed: () => context.go('/projects'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(context.tr('see_all'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),

          Consumer(
            builder: (context, ref, child) {
              final projectsState = ref.watch(projectsNotifierProvider);
              final activeProjects = projectsState.allProjects.where((p) => p.status == ProjectStatus.active).toList();

              if (activeProjects.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyActiveProjects(isDark: isDark),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ProjectCard(project: activeProjects[index], isDark: isDark),
                      ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
                    },
                    childCount: activeProjects.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: const _DashboardFAB(),
    );
  }
}

class _EmptyActiveProjects extends StatelessWidget {
  final bool isDark;
  const _EmptyActiveProjects({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.rocket_launch_rounded, 
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), 
          size: 80,
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('no_active_projects'),
          style: AppTextStyles.bold.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('start_journey'),
          style: AppTextStyles.medium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ── APP BAR ─────────────────────────────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'User';
    final now = DateTime.now();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        _AppBarAction(
          icon: Icons.notifications_none_rounded,
          hasBadge: true,
          isDark: isDark,
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/notifications');
          },
        ),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_getGreeting(context)}, $name',
              style: AppTextStyles.bold.copyWith(
                fontSize: 24,
                letterSpacing: -1,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              DateFormat('EEEE, MMMM dd').format(now),
              style: AppTextStyles.medium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (!isDark)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.03),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(BuildContext context) {
    final hour = DateTime.now().hour;
    if (hour < 12) return context.tr('good_morning');
    if (hour < 17) return context.tr('good_afternoon');
    if (hour < 21) return context.tr('good_evening');
    return context.tr('good_night');
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool hasBadge;
  final bool isDark;

  const _AppBarAction({
    required this.icon,
    required this.onTap,
    required this.isDark,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            onPressed: onTap,
            icon: Icon(
              icon, 
              color: Theme.of(context).colorScheme.onSurface, 
              size: 24
            ),
          ),
          if (hasBadge)
            Positioned(
              right: 14,
              top: 14,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.rose,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor, 
                    width: 1.5
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashboardStatusCards extends StatelessWidget {
  final int activeCount;
  final int completedCount;
  final int overdueCount;
  final bool isDark;

  const _DashboardStatusCards({
    required this.activeCount,
    required this.completedCount,
    required this.overdueCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            bottom: -30,
            child: Icon(
              Icons.analytics_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.05),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('mission_roadmap').toUpperCase(),
                style: AppTextStyles.bold.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusItem(
                    label: context.tr('status_active'),
                    count: activeCount,
                    icon: Icons.rocket_launch_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  _VerticalDivider(),
                  _StatusItem(
                    label: context.tr('status_completed'),
                    count: completedCount,
                    icon: Icons.check_circle_rounded,
                    color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.9),
                  ),
                  _VerticalDivider(),
                  _StatusItem(
                    label: context.tr('status_overdue'),
                    count: overdueCount,
                    icon: Icons.warning_rounded,
                    color: const Color(0xFFFDA4AF), // Light Rose
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutBack);
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 12),
        Text(
          count.toString().padLeft(2, '0'),
          style: AppTextStyles.bold.copyWith(
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: AppTextStyles.bold.copyWith(
            fontSize: 9,
            letterSpacing: 0.5,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0),
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0),
          ],
        ),
      ),
    );
  }
}

// ── PROJECT CARD ────────────────────────────────────────────────────────────

class _ProjectCard extends ConsumerWidget {
  final Project project;
  final bool isDark;
  const _ProjectCard({required this.project, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysRemaining = project.daysRemaining;
    final isOverdue = daysRemaining < 0;

    return DevCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/project-detail', extra: project.id),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        project.projectColor.withOpacity(0.4),
                        project.projectColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: project.projectColor.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.layers_rounded, 
                    color: Colors.white.withOpacity(0.9), 
                    size: 24
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bold.copyWith(
                          fontSize: 17,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOverdue ? Icons.error_outline_rounded : Icons.calendar_today_rounded,
                            size: 10,
                            color: isOverdue ? AppColors.rose : (daysRemaining <= 3 ? AppColors.amber : Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isOverdue 
                                ? context.tr('overdue_label') 
                                : '${daysRemaining.abs()} ${context.tr("days")} ${daysRemaining < 0 ? context.tr("ago") : context.tr("left")}',
                            style: AppTextStyles.medium.copyWith(
                              fontSize: 10,
                              color: isOverdue 
                                  ? AppColors.rose 
                                  : (daysRemaining <= 3 ? AppColors.amber : Theme.of(context).colorScheme.onSurfaceVariant),
                              fontWeight: (isOverdue || daysRemaining <= 3) ? FontWeight.w900 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  project: project, 
                  onStatusChanged: (newStatus) {
                    HapticFeedback.mediumImpact();
                    ref.read(projectsNotifierProvider.notifier).updateProjectStatus(project, newStatus);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('progress').toUpperCase(),
                      style: AppTextStyles.bold.copyWith(
                        fontSize: 9,
                        letterSpacing: 1,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${project.displayCompletedTasks}/${project.displayTotalTasks} ${context.tr(project.phases.isNotEmpty ? "modules" : "tasks")}',
                      style: AppTextStyles.semiBold.copyWith(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: project.projectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${(project.progressPercent * 100).toInt()}%',
                    style: AppTextStyles.bold.copyWith(
                      fontSize: 13,
                      color: project.projectColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ProgressBar(
              percent: project.progressPercent,
              color: project.projectColor,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Project project;
  final Function(ProjectStatus) onStatusChanged;
  const _StatusBadge({required this.project, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final statusColor = project.statusColor;
    return PopupMenuButton<ProjectStatus>(
      onSelected: onStatusChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              project.getStatusLabel(context).toUpperCase(), 
              style: TextStyle(
                color: statusColor, 
                fontSize: 9, 
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              )
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: statusColor),
          ],
        ),
      ),
      itemBuilder: (context) => ProjectStatus.values.map((s) {
        final tempProject = project.copyWith(status: s);
        return PopupMenuItem(
          value: s, 
          child: Text(
            tempProject.getStatusLabel(context), 
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)
          )
        );
      }).toList(),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  final Color color;
  final bool isDark;
  const _ProgressBar({required this.percent, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: percent.clamp(0.01, 1.0)),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutExpo,
                builder: (context, value, child) {
                  return Container(
                    width: constraints.maxWidth * value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardFAB extends StatelessWidget {
  const _DashboardFAB();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FloatingActionButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          context.push('/add-project');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Icon(
          Icons.add_rounded, 
          color: Theme.of(context).colorScheme.onPrimary, 
          size: 32
        ),
      ).animate().scale(delay: 800.ms, curve: Curves.easeOutBack),
    );
  }
}

