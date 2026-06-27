import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/models.dart';
import '../data/project_repository.dart';


import '../../../core/localization/app_localizations.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  final ProjectRepository _projectRepo = ProjectRepository();
  String _filterStatus = 'All';
  String _filterPriority = 'All';
  List<String> _getStatuses(BuildContext context) => ['All', context.tr('status_todo'), context.tr('status_in_progress'), context.tr('status_done')];
  List<String> _getPriorities(BuildContext context) => ['All', context.tr('priority_critical'), context.tr('priority_high'), context.tr('priority_medium'), context.tr('priority_low')];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawStatuses = ['All', 'To Do', 'In Progress', 'Done'];
    final rawPriorities = ['All', 'Critical', 'High', 'Medium', 'Low'];
    final statuses = _getStatuses(context);
    final priorities = _getPriorities(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFilters(isDark, statuses, priorities, rawStatuses, rawPriorities),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Project>>(
            stream: _projectRepo.getProjectsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
              }
              
              final projects = snapshot.data ?? [];
              final List<Map<String, dynamic>> allTasks = [];
              
              for (var project in projects) {
                for (var phase in project.phases) {
                  for (var task in phase.tasks) {
                    // Apply filters
                    bool matchesStatus = _filterStatus == 'All' || 
                        (task.status == TaskStatus.todo && _filterStatus == 'To Do') ||
                        (task.status == TaskStatus.inProgress && _filterStatus == 'In Progress') ||
                        (task.status == TaskStatus.done && _filterStatus == 'Done');
                        
                    bool matchesPriority = _filterPriority == 'All' || 
                        task.priority.name.toLowerCase() == _filterPriority.toLowerCase();

                    if (matchesStatus && matchesPriority) {
                      allTasks.add({
                        'project': project,
                        'phase': phase,
                        'task': task,
                      });
                    }
                  }
                }
              }

              if (allTasks.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(context, isDark),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = allTasks[index];
                      return _GlobalTaskCard(
                        project: item['project'],
                        phase: item['phase'],
                        task: item['task'],
                        isDark: isDark,
                      ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.1);
                    },
                    childCount: allTasks.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
        title: Text(
          context.tr('task_galaxy'),
          style: AppTextStyles.h2.copyWith(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                    : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -30,
              top: -30,
              child: Opacity(
                opacity: 0.1,
                child: const Icon(Icons.check_circle_rounded, size: 200, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark, List<String> statuses, List<String> priorities, List<String> rawStatuses, List<String> rawPriorities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(statuses.length, (i) => _FilterChip(
              label: statuses[i], 
              isSelected: _filterStatus == rawStatuses[i], 
              onTap: () => setState(() => _filterStatus = rawStatuses[i]),
              isDark: isDark,
            )),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: List.generate(priorities.length, (i) => _FilterChip(
              label: priorities[i], 
              isSelected: _filterPriority == rawPriorities[i], 
              onTap: () => setState(() => _filterPriority = rawPriorities[i]),
              isDark: isDark,
              isPriority: true,
            )),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.task_alt_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
        const SizedBox(height: 16),
        Text(
          context.tr('clear_horizon'),
          style: AppTextStyles.h3.copyWith(color: isDark ? Colors.white38 : Colors.grey.shade400),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('no_tasks_filters'),
          style: TextStyle(color: isDark ? Colors.white12 : Colors.grey.shade400, fontSize: 12),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final bool isPriority;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, required this.isDark, this.isPriority = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isPriority ? AppColors.rose : AppColors.indigo) 
            : (isDark ? const Color(0xFF161B22) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
              ? Colors.transparent 
              : (isDark ? const Color(0xFF30363D) : AppColors.borderLight),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white38 : AppColors.textSecondary),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _GlobalTaskCard extends StatelessWidget {
  final Project project;
  final Phase phase;
  final ProjectTask task;
  final bool isDark;

  const _GlobalTaskCard({required this.project, required this.phase, required this.task, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(task.priority);
    final statusColor = _getStatusColor(task.status, isDark, project.projectColor);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF30363D) : AppColors.borderLight.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: () => context.push('/project-detail', extra: project.id),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getPriorityLabel(context, task.priority),
                      style: TextStyle(color: priorityColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd', Localizations.localeOf(context).toString()).format(task.endDate),
                    style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.name,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.rocket_launch_rounded, size: 10, color: project.projectColor),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${project.name} • ${phase.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatusIndicator(status: task.status, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    _getStatusLabel(context, task.status).toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                  const Spacer(),
                  if (task.subtasks.isNotEmpty)
                    Text(
                      '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length} ${context.tr('steps').toUpperCase()}',
                      style: TextStyle(color: isDark ? Colors.white12 : Colors.grey.shade300, fontSize: 8, fontWeight: FontWeight.w900),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    return switch (p) {
      TaskPriority.critical => AppColors.purple,
      TaskPriority.high => AppColors.rose,
      TaskPriority.medium => AppColors.amber,
      TaskPriority.low => AppColors.emerald,
    };
  }

  Color _getStatusColor(TaskStatus s, bool isDark, Color accent) {
    return switch (s) {
      TaskStatus.done => AppColors.emerald,
      TaskStatus.inProgress => accent,
      TaskStatus.todo => isDark ? Colors.white24 : Colors.grey.shade400,
    };
  }

  String _getStatusLabel(BuildContext context, TaskStatus s) {
    return switch (s) {
      TaskStatus.done => context.tr('status_done'),
      TaskStatus.inProgress => context.tr('status_in_progress'),
      TaskStatus.todo => context.tr('status_todo'),
    };
  }

  String _getPriorityLabel(BuildContext context, TaskPriority p) {
    return switch (p) {
      TaskPriority.critical => context.tr('priority_critical'),
      TaskPriority.high => context.tr('priority_high'),
      TaskPriority.medium => context.tr('priority_medium'),
      TaskPriority.low => context.tr('priority_low'),
    }.toUpperCase();
  }
}

class _StatusIndicator extends StatelessWidget {
  final TaskStatus status;
  final Color color;
  const _StatusIndicator({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: status == TaskStatus.done 
        ? Center(child: Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)))
        : (status == TaskStatus.inProgress 
          ? Center(child: Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)))
          : null),
    );
  }
}
