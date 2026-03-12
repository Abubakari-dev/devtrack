# CRUD Quick Reference Card

Quick copy-paste snippets for common operations.

## Setup

```dart
import 'package:devtrack/core/services/crud_service.dart';
import 'package:uuid/uuid.dart';

final crud = CrudService();
final uuid = Uuid();
```

---

## Projects

```dart
// CREATE
final project = Project(id: uuid.v4(), name: 'My Project', ...);
await crud.createProject(project);

// READ
final project = await crud.getProject(projectId);
crud.getProjectsStream().listen((projects) { });

// UPDATE
await crud.updateProject(updatedProject, changeDescription: 'Updated');

// DELETE
await crud.deleteProject(projectId);

// DUPLICATE
final newId = await crud.duplicateProject(projectId, newName: 'Copy');

// PIN/UNPIN
await crud.toggleProjectPin(projectId, true);
```

---

## Phases

```dart
// CREATE
final phase = Phase(id: uuid.v4(), projectId: projectId, name: 'Phase 1', ...);
await crud.createPhase(projectId, phase);

// UPDATE
await crud.updatePhase(projectId, updatedPhase);

// DELETE
await crud.deletePhase(projectId, phaseId);
```

---

## Tasks

```dart
// CREATE
final task = ProjectTask(id: uuid.v4(), phaseId: phaseId, name: 'Task 1', ...);
await crud.createTask(projectId, phaseId, task);

// UPDATE
await crud.updateTask(projectId, phaseId, updatedTask);

// DELETE
await crud.deleteTask(projectId, phaseId, taskId);
```

---

## Subtasks

```dart
// CREATE
final subtask = Subtask(id: uuid.v4(), taskId: taskId, name: 'Subtask 1', ...);
await crud.createSubtask(projectId, phaseId, taskId, subtask);

// UPDATE
await crud.updateSubtask(projectId, phaseId, taskId, updatedSubtask);

// TOGGLE DONE
await crud.toggleSubtaskDone(projectId, phaseId, taskId, subtaskId, true);

// DELETE
await crud.deleteSubtask(projectId, phaseId, taskId, subtaskId);
```

---

## Clients

```dart
// CREATE
final client = Client(id: uuid.v4(), name: 'John Doe', ...);
await crud.createClient(client);

// READ
final client = await crud.getClient(clientId);
crud.getClientsStream().listen((clients) { });

// UPDATE
await crud.updateClient(updatedClient);

// DELETE (with safety check)
try {
  await crud.deleteClient(clientId);
} catch (e) {
  print('Cannot delete: $e');
}

// GET CLIENT PROJECTS
final projects = await crud.getProjectsForClient(clientId);
```

---

## Finance - Payments

```dart
// CREATE
final payment = Payment(id: uuid.v4(), projectId: projectId, amount: 1000, ...);
await crud.recordPayment(payment);

// READ
crud.getPaymentsForProject(projectId).listen((payments) { });
crud.getAllPayments().listen((payments) { });

// UPDATE
await crud.updatePayment(updatedPayment);

// DELETE
await crud.deletePayment(projectId, paymentId);
```

---

## Finance - Expenses

```dart
// CREATE
final expense = Expense(id: uuid.v4(), projectId: projectId, amount: 50, ...);
await crud.recordExpense(expense);

// READ
crud.getExpensesForProject(projectId).listen((expenses) { });
crud.getAllExpenses().listen((expenses) { });

// UPDATE
await crud.updateExpense(updatedExpense);

// DELETE
await crud.deleteExpense(projectId, expenseId);
```

---

## Notes

```dart
// CREATE
final note = ProjectNote(id: uuid.v4(), projectId: projectId, content: 'Note', ...);
await crud.createNote(note);

// READ
crud.getNotesForProject(projectId).listen((notes) { });

// UPDATE
await crud.updateNote(updatedNote);

// DELETE
await crud.deleteNote(projectId, noteId);
```

---

## Batch Operations

```dart
// BULK UPDATE STATUS
await crud.bulkUpdateProjectStatus(['id1', 'id2'], ProjectStatus.onHold);

// BULK DELETE
await crud.bulkDeleteProjects(['id1', 'id2']);

// AUTO ARCHIVE COMPLETED
final count = await crud.archiveCompletedProjects();
```

---

## Analytics

```dart
// PROJECT STATS
final stats = await crud.getProjectStatistics();
// Returns: totalProjects, activeProjects, completedProjects, totalRevenue, etc.

// FINANCIAL SUMMARY
final summary = await crud.getFinancialSummary();
// Returns: totalPayments, totalExpenses, netProfit

// OVERDUE TASKS
final overdue = await crud.getOverdueTasks();

// UPCOMING TASKS (next 7 days)
final upcoming = await crud.getUpcomingTasks(daysAhead: 7);

// PROJECT PROGRESS
final progress = crud.calculateProjectProgress(project);

// PROJECT HEALTH
final health = crud.getProjectHealth(project);
// Returns: 'completed', 'on_track', 'at_risk', 'critical'
```

---

## Search & Filter

```dart
// SEARCH
final results = await crud.searchProjects('keyword');

// FILTER BY STATUS
final active = await crud.filterProjectsByStatus(ProjectStatus.active);

// FILTER BY CATEGORY
final mobile = await crud.filterProjectsByCategory(ProjectCategory.mobile);

// FILTER BY TAG
final urgent = await crud.filterProjectsByTag('urgent');

// GET ALL TAGS
final tags = await crud.getAllTags();
```

---

## Activity Logs

```dart
// GET LOGS
crud.getActivityLogsForProject(projectId).listen((logs) { });

// LOG CUSTOM ACTIVITY
await crud.logCustomActivity(projectId, 'Custom action');
```

---

## Common Patterns

### StreamBuilder Pattern

```dart
StreamBuilder<List<Project>>(
  stream: crud.getProjectsStream(),
  builder: (context, snapshot) {
    if (snapshot.hasError) return Text('Error: ${snapshot.error}');
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final projects = snapshot.data!;
    return ListView.builder(
      itemCount: projects.length,
      itemBuilder: (context, i) => ProjectCard(project: projects[i]),
    );
  },
)
```

### Error Handling Pattern

```dart
try {
  await crud.deleteClient(clientId);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Client deleted')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

### Update Pattern

```dart
final project = await crud.getProject(projectId);
if (project != null) {
  final updated = Project(
    id: project.id,
    name: 'New Name',
    // ... copy other fields
  );
  await crud.updateProject(updated);
}
```

---

## Enums Reference

```dart
// Project Status
ProjectStatus.active
ProjectStatus.completed
ProjectStatus.onHold

// Project Category
ProjectCategory.mobile
ProjectCategory.website
ProjectCategory.desktop
ProjectCategory.other

// Task Priority
TaskPriority.high
TaskPriority.medium
TaskPriority.low

// Payment Status
PaymentStatus.received
PaymentStatus.pending
```

---

## Tips

1. Always use `uuid.v4()` for new IDs
2. Use streams for real-time UI updates
3. Provide `changeDescription` for better activity logs
4. Handle errors with try-catch
5. Check for null when getting single entities
6. Dispose stream subscriptions in `dispose()`
7. Use batch operations for multiple updates

---

**Need more details?** Check `crud_usage_guide.md` for comprehensive documentation.
