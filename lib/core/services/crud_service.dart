import 'firestore_service.dart';
import 'auth_service.dart';
import '../../features/projects/models/models.dart';
import '../../features/projects/data/project_repository.dart';
import 'package:uuid/uuid.dart';

class CrudService {
  final AuthService _authService = AuthService();
  final ProjectRepository _projectRepo = ProjectRepository();
  final _uuid = const Uuid();
  
  FirestoreService? get _firestore {
    final user = _authService.currentUser;
    if (user != null) return FirestoreService(uid: user.uid);
    return null;
  }

  // ─── PROJECT CRUD ──────────────────────────────────────────────────────────

  Future<void> saveProject(Project project) async {
    await _projectRepo.saveProject(project);
  }

  Future<void> deleteProject(String projectId) async {
    await _projectRepo.deleteProject(projectId);
  }

  Future<Project?> getProject(String projectId) async {
    return await _projectRepo.getProject(projectId);
  }

  Stream<List<Project>> getProjectsStream() {
    return _projectRepo.getProjectsStream();
  }

  Future<String> duplicateProject(String projectId, {String? newName}) async {
    final original = await getProject(projectId);
    if (original == null) throw Exception('Original project not found');

    final newProject = original.copyWith(
      id: _uuid.v4(),
      name: newName ?? '${original.name} (Copy)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: ProjectStatus.planned,
      progress: 0,
      completedTasks: 0,
    );

    await saveProject(newProject);
    return newProject.id;
  }

  // ─── CLIENT CRUD ───────────────────────────────────────────────────────────

  Stream<List<Client>> getClientsStream() {
    return _firestore?.getClients() ?? Stream.value([]);
  }

  // ─── FINANCE CRUD ──────────────────────────────────────────────────────────

  Stream<List<Payment>> getAllPayments() {
    return _firestore?.getAllPayments() ?? Stream.value([]);
  }

  Stream<List<Expense>> getAllExpenses() {
    return _firestore?.getAllExpenses() ?? Stream.value([]);
  }

  // ─── ANALYTICS ─────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProjectStatistics() async {
    final projects = await _projectRepo.getProjectsStream().first;
    
    double totalRevenue = 0;
    int active = 0;
    int completed = 0;
    
    for (var p in projects) {
      totalRevenue += p.totalPrice;
      if (p.status == ProjectStatus.active) active++;
      if (p.status == ProjectStatus.completed) completed++;
    }

    return {
      'totalProjects': projects.length,
      'activeProjects': active,
      'completedProjects': completed,
      'totalRevenue': totalRevenue,
      'completionRate': projects.isEmpty ? 0 : (completed / projects.length) * 100,
    };
  }

  // ─── SEARCH & FILTER ───────────────────────────────────────────────────────

  Future<List<Project>> searchProjects(String query) async {
    final projects = await _projectRepo.getProjectsStream().first;
    final lowercaseQuery = query.toLowerCase();
    
    return projects.where((p) => 
      p.name.toLowerCase().contains(lowercaseQuery) || 
      (p.description?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }
}
