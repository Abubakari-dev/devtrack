import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../data/project_repository.dart';
import '../models/project_model.dart';
import '../bloc/projects_cubit.dart';
import 'project_detail_screen.dart';
import 'add_edit_project_screen.dart';
import '../../finance/screens/project_expenses_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => ProjectRepository(),
      child: BlocProvider(
        create: (context) => ProjectsCubit(context.read<ProjectRepository>())..init(),
        child: const _ProjectsScreenView(),
      ),
    );
  }
}

class _ProjectsScreenView extends StatefulWidget {
  const _ProjectsScreenView();

  @override
  State<_ProjectsScreenView> createState() => _ProjectsScreenViewState();
}

class _ProjectsScreenViewState extends State<_ProjectsScreenView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  static const _filters = ['All', 'Planned', 'Active', 'On Hold', 'Completed'];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {});
    context.read<ProjectsCubit>().setSearchQuery(query);
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ProjectsCubit>().setSearchQuery('');
    setState(() {});
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppColors.surface,
      body: BlocListener<ProjectsCubit, ProjectsState>(
        listenWhen: (prev, curr) => prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!), backgroundColor: AppColors.rose),
          );
        },
        child: RefreshIndicator(
          onRefresh: () async => context.read<ProjectsCubit>().init(),
          displacement: 100,
          color: AppColors.indigo,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverHeader(context, isDark),
              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: _buildFilters(context, isDark),
                ),
              ),

              const _ProjectsContentSliver(),
              
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverHeader(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.indigo,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: EdgeInsets.zero,
        background: Container(
          decoration: const BoxDecoration(gradient: AppColors.indigoGradient),
          child: Stack(
            children: [
              Positioned(top: -10, right: -10, child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.05))),
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'All Projects',
                      style: AppTextStyles.h2(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSearchBar(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1F2328),
        ),
        decoration: InputDecoration(
          hintText: 'Search workspace...',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: AppColors.indigo,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 18),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context, bool isDark) {
    final currentFilter = context.select((ProjectsCubit c) => c.state.filter);
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((f) {
          final isSelected = currentFilter == f;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _FilterChip(
              label: f,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => context.read<ProjectsCubit>().setFilter(f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo.withOpacity(0.35), 
            blurRadius: 18, 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProjectScreen())),
        backgroundColor: AppColors.indigo,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: const Text('NEW PROJECT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.0)),
      ),
    ).animate().scale(delay: 400.ms, duration: 300.ms, curve: Curves.easeOutBack);
  }
}

class _ProjectsContentSliver extends StatelessWidget {
  const _ProjectsContentSliver();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<ProjectsCubit, ProjectsState>(
      builder: (context, state) {
        if (state.status == ProjectsStatus.loading) {
          return SliverToBoxAdapter(child: _ShimmerLoading(isDark: isDark));
        }

        if (state.status == ProjectsStatus.failure) {
          return SliverToBoxAdapter(child: _ErrorView(error: state.errorMessage ?? 'Unknown error', onRetry: () => context.read<ProjectsCubit>().init()));
        }

        if (state.allProjects.isEmpty) {
          return SliverToBoxAdapter(child: _EmptyView(isNoData: true, isDark: isDark));
        }

        if (state.filteredProjects.isEmpty) {
          return SliverToBoxAdapter(child: _EmptyView(
            isNoData: false, 
            isDark: isDark, 
            searchQuery: state.searchQuery, 
            activeFilter: state.filter,
            onClear: () => context.read<ProjectsCubit>().clearAllFilters(),
          ));
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final p = state.filteredProjects[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Dismissible(
                    key: Key(p.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      decoration: BoxDecoration(color: AppColors.rose, borderRadius: BorderRadius.circular(24)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                    ),
                    confirmDismiss: (_) => showDialog<bool>(context: context, builder: (context) => _DeleteConfirmDialog(projectName: p.name, isDark: isDark)),
                    onDismissed: (_) => context.read<ProjectsCubit>().deleteProject(p.id),
                    child: _ProjectCard(
                      project: p, 
                      isDark: isDark, 
                      onStatusChanged: (s) => context.read<ProjectsCubit>().updateProjectStatus(p, s),
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, curve: Curves.easeOutQuad);
              },
              childCount: state.filteredProjects.length,
            ),
          ),
        );
      },
    );
  }
}

class _ProjectCard extends StatelessWidget {
  final Project project;
  final bool isDark;
  final Function(ProjectStatus) onStatusChanged;
  const _ProjectCard({required this.project, required this.isDark, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
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
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectExpensesScreen(project: project),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.receipt_long_rounded,
                    color: AppColors.amber,
                    size: 18,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.amber.withOpacity(0.12),
                    padding: const EdgeInsets.all(10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  tooltip: 'View Expenses',
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                  project: project,
                  onStatusChanged: onStatusChanged,
                  isDark: isDark,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.indigo 
              : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected 
                ? AppColors.indigo 
                : (isDark ? Colors.white.withOpacity(0.1) : AppColors.borderLight.withOpacity(0.5)),
            width: 1.5,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.indigo.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Project project;
  final bool isDark;
  final Function(ProjectStatus) onStatusChanged;
  const _StatusBadge({required this.project, required this.isDark, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    final statusColor = project.statusColor;
    return PopupMenuButton<ProjectStatus>(
      onSelected: onStatusChanged,
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1), 
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              project.statusLabel.toUpperCase(), 
              style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: statusColor),
          ],
        ),
      ),
      itemBuilder: (context) => ProjectStatus.values.map((s) => PopupMenuItem(
        value: s, 
        child: Text(s.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))
      )).toList(),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final bool isNoData;
  final bool isDark;
  final String? searchQuery;
  final String? activeFilter;
  final VoidCallback? onClear;
  
  const _EmptyView({required this.isNoData, required this.isDark, this.searchQuery, this.activeFilter, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNoData ? Icons.rocket_launch_rounded : Icons.search_off_rounded, 
                size: 48, 
                color: isDark ? Colors.white24 : AppColors.border
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isNoData ? 'No missions found' : 'No matches', 
              style: AppTextStyles.h2(context).copyWith(
                color: isDark ? Colors.white : Colors.black, 
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5
              )
            ),
            const SizedBox(height: 12),
            Text(
              isNoData 
                ? 'Your project hub is clear. Time to start a new mission!' 
                : 'We couldn\'t find any projects matching your search criteria.', 
              textAlign: TextAlign.center,
              style: AppTextStyles.body(context).copyWith(
                color: isDark ? Colors.white38 : AppColors.textMuted,
                height: 1.5
              )
            ),
            if (!isNoData && onClear != null) ...[
              const SizedBox(height: 32),
              TextButton(
                onPressed: onClear, 
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.indigo.withOpacity(0.2)))
                ),
                child: const Text('Clear all filters', style: TextStyle(color: AppColors.indigo, fontWeight: FontWeight.w900, fontSize: 13))
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9));
  }
}

class _ShimmerLoading extends StatelessWidget {
  final bool isDark;
  const _ShimmerLoading({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(children: List.generate(3, (i) => Container(height: 140, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(28))))),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.rose, size: 48),
          const SizedBox(height: 16),
          const Text('Sync Failed', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry Sync')),
        ],
      ),
    );
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  final String projectName;
  final bool isDark;
  const _DeleteConfirmDialog({required this.projectName, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF161B22) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Delete Mission?', style: TextStyle(fontWeight: FontWeight.w900)),
      content: Text('This will permanently delete "$projectName" and all its roadmap data.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('KEEP IT', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), 
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.rose, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), 
          child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))
        ),
      ],
    );
  }
}
