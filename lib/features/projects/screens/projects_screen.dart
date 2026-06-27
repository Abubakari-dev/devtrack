import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/localization/app_localizations.dart';
import 'package:devtrack/features/projects/models/models.dart';
import '../providers/projects_providers.dart';
import '../../../../core/widgets/dev_card.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(projectsNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const _ProjectsHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: _SearchBar(),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: _FilterControls(),
            ),
          ),
          if (state.searchQuery.isNotEmpty && state.filteredProjects.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  '${state.filteredProjects.length} ${context.tr('items').toLowerCase()} found',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(),
              ),
            ),
          _buildContent(context, state, ref),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildContent(BuildContext context, ProjectsState state, WidgetRef ref) {
    if (state.status == ProjectsStatus.loading) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2, 
            color: Theme.of(context).colorScheme.secondary
          ),
        ),
      );
    }

    if (state.status == ProjectsStatus.failure) {
      return SliverFillRemaining(
        child: _ErrorView(
          error: state.errorMessage ?? 'Unknown error', 
          onRetry: () => ref.read(projectsNotifierProvider.notifier).init()
        ),
      );
    }

    if (state.allProjects.isEmpty) {
      return const SliverFillRemaining(child: _EmptyView(isNoData: true));
    }

    if (state.filteredProjects.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyView(
          isNoData: false, 
          onClear: () => ref.read(projectsNotifierProvider.notifier).clearAllFilters(),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = state.filteredProjects[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ProjectCard(
                project: p, 
                onStatusChanged: (s) {
                  HapticFeedback.mediumImpact();
                  ref.read(projectsNotifierProvider.notifier).updateProjectStatus(p, s);
                },
              ),
            ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, duration: 400.ms);
          },
          childCount: state.filteredProjects.length,
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        context.push('/add-project');
      },
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Icon(
        Icons.add_rounded, 
        color: Theme.of(context).colorScheme.onPrimary, 
        size: 28
      ),
      label: Text(
        context.tr('new_project'),
        style: AppTextStyles.semiBold.copyWith(
          color: Theme.of(context).colorScheme.onPrimary, 
          fontSize: 14, 
          letterSpacing: 0.5
        ),
      ),
    ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack);
  }
}

class _ProjectsHeader extends StatelessWidget {
  const _ProjectsHeader();

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push('/tasks');
            },
            icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
            tooltip: context.tr('global_tasks'),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Text(
          context.tr('all_projects'),
          style: AppTextStyles.bold.copyWith(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -30,
              child: Opacity(
                opacity: 0.1,
                child: const Icon(Icons.rocket_launch_rounded, size: 120, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: ref.read(projectsNotifierProvider).searchQuery);
    
    ref.listen(projectsNotifierProvider.select((s) => s.searchQuery), (prev, next) {
      if (next.isEmpty && controller.text.isNotEmpty) {
        controller.clear();
      }
    });

    return DevCard(
      padding: EdgeInsets.zero,
      borderRadius: 16,
      showBorder: Theme.of(context).brightness == Brightness.light,
      child: TextField(
        controller: controller,
        onChanged: (query) {
          ref.read(projectsNotifierProvider.notifier).setSearchQuery(query);
        },
        style: AppTextStyles.semiBold.copyWith(
          fontSize: 15,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: context.tr('search_projects'),
          hintStyle: AppTextStyles.medium.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant, 
            fontSize: 14
          ),
          prefixIcon: Icon(
            Icons.search_rounded, 
            color: Theme.of(context).colorScheme.primary, 
            size: 20
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.clear();
                    ref.read(projectsNotifierProvider.notifier).setSearchQuery('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _FilterControls extends ConsumerWidget {
  const _FilterControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(projectsNotifierProvider.select((s) => s.filter));
    final labels = [
      'All', 
      context.tr('status_planned'), 
      context.tr('status_active'), 
      context.tr('status_on_hold'), 
      context.tr('status_completed')
    ];
    final values = ['All', 'Planned', 'Active', 'On Hold', 'Completed'];
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(labels.length, (index) {
          final label = labels[index];
          final value = values[index];
          final isSelected = currentFilter == value;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(projectsNotifierProvider.notifier).setFilter(value);
              },
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: 250.ms,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ] : null,
                  border: Border.all(
                    color: isSelected 
                        ? Colors.transparent 
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                child: Text(
                  label,
                  style: AppTextStyles.bold.copyWith(
                    color: isSelected 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final Function(ProjectStatus) onStatusChanged;
  
  const _ProjectCard({
    required this.project, 
    required this.onStatusChanged
  });

  @override
  Widget build(BuildContext context) {
    final daysRemaining = project.daysRemaining;
    final isOverdue = daysRemaining < 0;

    return DevCard(
      onTap: () => context.push('/project-detail', extra: project.id),
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
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
                      )
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            project.getCategoryLabel(context), 
                            style: AppTextStyles.bold.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 10,
                            )
                          ),
                        ),
                        const SizedBox(width: 8),
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
                )
              ),
              _StatusBadge(project: project, onStatusChanged: onStatusChanged),
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
                    )
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
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ProgressBar(
            percent: project.progressPercent,
            color: project.projectColor,
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double percent;
  final Color color;
  const _ProgressBar({required this.percent, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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

class _EmptyView extends StatelessWidget {
  final bool isNoData;
  final VoidCallback? onClear;
  const _EmptyView({required this.isNoData, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isNoData ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary).withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoData ? Icons.rocket_launch_rounded : Icons.search_off_rounded, 
                size: 64, 
                color: (isNoData ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary).withOpacity(0.5)
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isNoData ? context.tr('no_projects') : context.tr('no_matches'), 
              style: AppTextStyles.bold.copyWith(
                fontSize: 20, 
                letterSpacing: -0.5,
                color: Theme.of(context).colorScheme.onSurface
              )
            ),
            const SizedBox(height: 12),
            Text(
              isNoData ? context.tr('time_to_start') : context.tr('try_different_search'),
              textAlign: TextAlign.center,
              style: AppTextStyles.medium.copyWith(
                fontSize: 14, 
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (!isNoData && onClear != null) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: onClear, 
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  context.tr('clear_filters'), 
                  style: AppTextStyles.bold.copyWith(
                    color: Theme.of(context).colorScheme.primary, 
                    fontSize: 13
                  )
                )
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 48),
            const SizedBox(height: 16),
            Text(
              context.tr('error'), 
              style: AppTextStyles.bold.copyWith(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface
              )
            ),
            const SizedBox(height: 8),
            Text(
              error, 
              textAlign: TextAlign.center, 
              style: AppTextStyles.medium.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant
              )
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry, 
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
              child: Text(context.tr('retry'))
            ),
          ],
        ),
      ),
    );
  }
}
