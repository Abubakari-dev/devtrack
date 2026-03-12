import 'firestore_service.dart';
import 'auth_service.dart';
import '../../features/projects/models/project_model.dart';
import '../../features/projects/data/project_repository.dart';

class CrudService {
  final AuthService _authService = AuthService();
  final ProjectRepository _projectRepo = ProjectRepository();
  
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
}
