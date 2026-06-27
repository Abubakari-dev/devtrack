import 'package:devtrack/features/projects/models/models.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'package:devtrack/features/projects/data/project_repository.dart';

// ── STATE ──────────────────────────────────────────────────────────────────
enum ProjectsStatus { initial, loading, success, failure }

class ProjectsState extends Equatable {
  final ProjectsStatus status;
  final List<Project> allProjects;
  final List<Project> filteredProjects;
  final String filter;
  final String searchQuery;
  final String? errorMessage;

  const ProjectsState({
    this.status = ProjectsStatus.initial,
    this.allProjects = const [],
    this.filteredProjects = const [],
    this.filter = 'All',
    this.searchQuery = '',
    this.errorMessage,
  });

  ProjectsState copyWith({
    ProjectsStatus? status,
    List<Project>? allProjects,
    List<Project>? filteredProjects,
    String? filter,
    String? searchQuery,
    String? errorMessage,
  }) {
    return ProjectsState(
      status: status ?? this.status,
      allProjects: allProjects ?? this.allProjects,
      filteredProjects: filteredProjects ?? this.filteredProjects,
      filter: filter ?? this.filter,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, allProjects, filteredProjects, filter, searchQuery, errorMessage];
}

// ── REPOSITORY PROVIDER ─────────────────────────────────────────────────────
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

final allProjectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(projectRepositoryProvider).getProjectsStream();
});

// ── NOTIFIER ────────────────────────────────────────────────────────────────
class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ProjectRepository _repository;
  StreamSubscription? _subscription;

  ProjectsNotifier(this._repository) : super(const ProjectsState()) {
    init();
  }

  void init() {
    state = state.copyWith(status: ProjectsStatus.loading);
    _subscription?.cancel();
    _subscription = _repository.getProjectsStream().listen(
      (projects) {
        _updateList(projects: projects);
      },
      onError: (e) {
        state = state.copyWith(status: ProjectsStatus.failure, errorMessage: e.toString());
      },
    );
  }

  void setFilter(String filter) {
    _updateList(filter: filter);
  }

  void setSearchQuery(String query) {
    _updateList(searchQuery: query);
  }

  void clearAllFilters() {
    _updateList(filter: 'All', searchQuery: '');
  }

  void _updateList({List<Project>? projects, String? filter, String? searchQuery}) {
    final currentProjects = projects ?? state.allProjects;
    final currentFilter = filter ?? state.filter;
    final currentQuery = searchQuery ?? state.searchQuery;

    var filtered = List<Project>.from(currentProjects);

    // 1. Search filter
    if (currentQuery.isNotEmpty) {
      final q = currentQuery.toLowerCase();
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(q) || 
               (p.description?.toLowerCase().contains(q) ?? false) ||
               p.categoryLabel.toLowerCase().contains(q);
      }).toList();
    }

    // 2. Status filter
    if (currentFilter != 'All') {
      filtered = filtered.where((p) => p.statusLabel.toLowerCase() == currentFilter.toLowerCase()).toList();
    }

    // 3. Sorting (Business Logic)
    filtered.sort((a, b) {
      if (a.status == ProjectStatus.overdue && b.status != ProjectStatus.overdue) return -1;
      if (b.status == ProjectStatus.overdue && a.status != ProjectStatus.overdue) return 1;
      return a.endDate.compareTo(b.endDate);
    });

    state = state.copyWith(
      status: ProjectsStatus.success,
      allProjects: currentProjects,
      filteredProjects: filtered,
      filter: currentFilter,
      searchQuery: currentQuery,
    );
  }

  Future<void> updateProjectStatus(Project project, ProjectStatus status) async {
    try {
      await _repository.updateProject(project.copyWith(status: status));
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update status');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _repository.deleteProject(id);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete project');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final projectsNotifierProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>((ref) {
  return ProjectsNotifier(ref.watch(projectRepositoryProvider));
});
