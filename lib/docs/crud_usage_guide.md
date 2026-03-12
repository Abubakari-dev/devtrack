# CRUD Service Usage Guide

Complete guide for using the CrudService to manage all app entities.

## Table of Contents
1. [Overview](#overview)
2. [Project Operations](#project-operations)
3. [Phase Operations](#phase-operations)
4. [Task Operations](#task-operations)
5. [Subtask Operations](#subtask-operations)
6. [Client Operations](#client-operations)
7. [Finance Operations](#finance-operations)
8. [Notes Operations](#notes-operations)
9. [Batch Operations](#batch-operations)
10. [Analytics & Statistics](#analytics--statistics)
11. [Search & Filter](#search--filter)

---

## Overview

The `CrudService` provides a unified interface for all CRUD operations across the app. It automatically handles:
- Activity logging for all changes
- Data validation
- Related data cleanup on deletion
- Error handling

### Setup

```dart
import 'package:devtrack/core/services/crud_service.dart';

final crudService = CrudService();
```

---

## Project Operations

### Create Project

```dart
final project = Project(
  id: uuid.v4(),
  name: 'E-Commerce Mobile App',
  clientName: 'John Doe',
  clientId: 'client_123',
  category: ProjectCategory.mobile,
  status: ProjectStatus.active,
  totalPrice: 5000.0,
  advanceAmount: 2000.0,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 90)),
  description: 'Full-featured e-commerce app',
  isPinned: false,
  tags: ['urgent', 'mobile'],
  phases: [],
);

final projectId = await crudService.createProject(project);
```

### Update Project

```dart
final project = await crudService.getProject(projectId);
if (project != null) {
  final updated = project.copyWith(
    name: 'Updated Project Name',
    totalPrice: 6000.0,
    isPinned: true,
  );
  
  await crudService.updateProject(
    updated,
    changeDescription: 'Updated price and pinned project',
  );
}
```

### Delete Project

```dart
// Deletes project and ALL related data (phases, tasks, subtasks, notes, logs, payments, expenses)
await crudService.deleteProject(projectId);
```

### Get Projects

```dart
// Stream of all projects (real-time updates)
crudService.getProjectsStream().listen((projects) {
  print('Total projects: ${projects.length}');
});

// Get single project
final project = await crudService.getProject(projectId);
```

### Toggle Pin

```dart
await crudService.toggleProjectPin(projectId, true); // Pin
await crudService.toggleProjectPin(projectId, false); // Unpin
```

### Duplicate Project

```dart
// Duplicates project with all phases, tasks, and subtasks
final newProjectId = await crudService.duplicateProject(
  projectId,
  newName: 'Project Copy',
);
```

---

## Phase Operations

### Create Phase

```dart
final phase = Phase(
  id: uuid.v4(),
  projectId: projectId,
  name: 'Design Phase',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 30)),
  orderIndex: 0,
  tasks: [],
);

await crudService.createPhase(projectId, phase);
```

### Update Phase

```dart
final updated = phase.copyWith(
  name: 'Updated Phase Name',
  endDate: phase.endDate.add(Duration(days: 7)),
);

await crudService.updatePhase(projectId, updated);
```

### Delete Phase

```dart
// Deletes phase and all its tasks and subtasks
await crudService.deletePhase(projectId, phaseId);
```

---

## Task Operations

### Create Task

```dart
final task = ProjectTask(
  id: uuid.v4(),
  phaseId: phaseId,
  name: 'Create UI Wireframes',
  priority: TaskPriority.high,
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 7)),
  subtasks: [],
);

await crudService.createTask(projectId, phaseId, task);
```

### Update Task

```dart
final updated = task.copyWith(
  name: 'Updated Task Name',
  priority: TaskPriority.medium,
);

await crudService.updateTask(projectId, phaseId, updated);
```

### Delete Task

```dart
// Deletes task and all its subtasks
await crudService.deleteTask(projectId, phaseId, taskId);
```

---

## Subtask Operations

### Create Subtask

```dart
final subtask = Subtask(
  id: uuid.v4(),
  taskId: taskId,
  name: 'Design login screen',
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 2)),
  isDone: false,
  reminderDate: DateTime.now().add(Duration(days: 1)),
);

await crudService.createSubtask(projectId, phaseId, taskId, subtask);
```

### Update Subtask

```dart
final updated = subtask.copyWith(
  name: 'Updated Subtask Name',
  endDate: subtask.endDate.add(Duration(days: 1)),
);

await crudService.updateSubtask(projectId, phaseId, taskId, updated);
```

### Toggle Completion

```dart
// Mark as done
await crudService.toggleSubtaskDone(
  projectId, phaseId, taskId, subtaskId, true
);

// Mark as not done
await crudService.toggleSubtaskDone(
  projectId, phaseId, taskId, subtaskId, false
);
```

### Delete Subtask

```dart
await crudService.deleteSubtask(projectId, phaseId, taskId, subtaskId);
```

---

## Client Operations

### Create Client

```dart
final client = Client(
  id: uuid.v4(),
  name: 'John Doe',
  company: 'Tech Solutions Inc.',
  email: 'john@techsolutions.com',
  phone: '+1234567890',
  location: 'New York, USA',
);

final clientId = await crudService.createClient(client);
```

### Update Client

```dart
final updated = client.copyWith(
  company: 'Updated Company Name',
  phone: '+9876543210',
);

await crudService.updateClient(updated);
```

### Delete Client

```dart
try {
  await crudService.deleteClient(clientId);
} catch (e) {
  // Error thrown if projects are linked to this client
  print('Cannot delete: $e');
}
```

### Get Clients

```dart
// Stream of all clients
crudService.getClientsStream().listen((clients) {
  print('Total clients: ${clients.length}');
});

// Get single client
final client = await crudService.getClient(clientId);

// Get projects for a client
final projects = await crudService.getProjectsForClient(clientId);
```

---

## Finance Operations

### Record Payment

```dart
final payment = Payment(
  id: uuid.v4(),
  projectId: projectId,
  label: 'First Milestone Payment',
  amount: 1500.0,
  date: DateTime.now(),
  status: PaymentStatus.received,
);

final paymentId = await crudService.recordPayment(payment);
```

### Update Payment

```dart
final updated = payment.copyWith(
  amount: 2000.0,
  status: PaymentStatus.received,
);

await crudService.updatePayment(updated);
```

### Delete Payment

```dart
await crudService.deletePayment(projectId, paymentId);
```

### Get Payments

```dart
// Payments for a project
crudService.getPaymentsForProject(projectId).listen((payments) {
  print('Total payments: ${payments.length}');
});

// All payments
crudService.getAllPayments().listen((payments) {
  print('Total payments across all projects: ${payments.length}');
});
```

### Record Expense

```dart
final expense = Expense(
  id: uuid.v4(),
  projectId: projectId,
  name: 'Cloud Hosting',
  amount: 50.0,
  date: DateTime.now(),
  category: 'Infrastructure',
);

final expenseId = await crudService.recordExpense(expense);
```

### Update Expense

```dart
final updated = expense.copyWith(
  amount: 75.0,
  category: 'Updated Category',
);

await crudService.updateExpense(updated);
```

### Delete Expense

```dart
await crudService.deleteExpense(projectId, expenseId);
```

### Get Expenses

```dart
// Expenses for a project
crudService.getExpensesForProject(projectId).listen((expenses) {
  print('Total expenses: ${expenses.length}');
});

// All expenses
crudService.getAllExpenses().listen((expenses) {
  print('Total expenses across all projects: ${expenses.length}');
});
```

---

## Notes Operations

### Create Note

```dart
final note = ProjectNote(
  id: uuid.v4(),
  projectId: projectId,
  content: 'Client requested additional features',
  createdAt: DateTime.now(),
);

final noteId = await crudService.createNote(note);
```

### Update Note

```dart
final updated = ProjectNote(
  id: note.id,
  projectId: note.projectId,
  content: 'Updated note content',
  createdAt: note.createdAt,
);

await crudService.updateNote(updated);
```

### Delete Note

```dart
await crudService.deleteNote(projectId, noteId);
```

### Get Notes

```dart
crudService.getNotesForProject(projectId).listen((notes) {
  print('Total notes: ${notes.length}');
});
```

---

## Batch Operations

### Bulk Update Status

```dart
final projectIds = ['project1', 'project2', 'project3'];
await crudService.bulkUpdateProjectStatus(
  projectIds,
  ProjectStatus.onHold,
);
```

### Bulk Delete

```dart
final projectIds = ['project1', 'project2'];
await crudService.bulkDeleteProjects(projectIds);
```

### Archive Completed Projects

```dart
// Automatically archives projects where all subtasks are done
final count = await crudService.archiveCompletedProjects();
print('$count project(s) archived');
```

---

## Analytics & Statistics

### Project Statistics

```dart
final stats = await crudService.getProjectStatistics();

print('Total Projects: ${stats['totalProjects']}');
print('Active: ${stats['activeProjects']}');
print('Completed: ${stats['completedProjects']}');
print('On Hold: ${stats['onHoldProjects']}');
print('Total Revenue: \$${stats['totalRevenue']}');
print('Total Received: \$${stats['totalReceived']}');
print('Total Remaining: \$${stats['totalRemaining']}');
print('Completion Rate: ${stats['completionRate']}%');
```

### Financial Summary

```dart
final summary = await crudService.getFinancialSummary();

print('Total Payments: \$${summary['totalPayments']}');
print('Total Expenses: \$${summary['totalExpenses']}');
print('Net Profit: \$${summary['netProfit']}');
print('Payment Count: ${summary['paymentCount']}');
print('Expense Count: ${summary['expenseCount']}');
```

### Overdue Tasks

```dart
final overdue = await crudService.getOverdueTasks();

for (final task in overdue) {
  print('${task['subtaskName']} - ${task['daysOverdue']} days overdue');
  print('Project: ${task['projectName']}');
  print('Phase: ${task['phaseName']}');
}
```

### Upcoming Tasks

```dart
// Get tasks due in next 7 days
final upcoming = await crudService.getUpcomingTasks(daysAhead: 7);

for (final task in upcoming) {
  print('${task['subtaskName']} - due in ${task['daysUntilDue']} days');
}
```

### Project Progress

```dart
final project = await crudService.getProject(projectId);
if (project != null) {
  final progress = crudService.calculateProjectProgress(project);
  print('Progress: ${progress.toStringAsFixed(1)}%');
}
```

### Project Health

```dart
final project = await crudService.getProject(projectId);
if (project != null) {
  final health = crudService.getProjectHealth(project);
  // Returns: 'completed', 'on_track', 'at_risk', or 'critical'
  print('Health: $health');
}
```

---

## Search & Filter

### Search Projects

```dart
// Search by name or description
final results = await crudService.searchProjects('mobile');
print('Found ${results.length} matching projects');
```

### Filter by Status

```dart
final active = await crudService.filterProjectsByStatus(ProjectStatus.active);
final completed = await crudService.filterProjectsByStatus(ProjectStatus.completed);
final onHold = await crudService.filterProjectsByStatus(ProjectStatus.onHold);
```

### Filter by Category

```dart
final mobile = await crudService.filterProjectsByCategory(ProjectCategory.mobile);
final website = await crudService.filterProjectsByCategory(ProjectCategory.website);
final desktop = await crudService.filterProjectsByCategory(ProjectCategory.desktop);
```

### Filter by Tag

```dart
final urgent = await crudService.filterProjectsByTag('urgent');
```

### Get All Tags

```dart
final tags = await crudService.getAllTags();
print('Available tags: ${tags.join(', ')}');
```

---

## Activity Logging

All CRUD operations automatically log activities. You can also log custom activities:

```dart
await crudService.logCustomActivity(
  projectId,
  'Custom activity description',
);

// View activity logs
crudService.getActivityLogsForProject(projectId).listen((logs) {
  for (final log in logs) {
    print('${log.timestamp}: ${log.action}');
  }
});
```

---

## Best Practices

1. **Always use CrudService** instead of calling repositories directly
2. **Handle errors** with try-catch blocks
3. **Use streams** for real-time updates in UI
4. **Provide change descriptions** when updating for better activity logs
5. **Check for null** when getting single entities
6. **Use batch operations** for multiple updates to improve performance
7. **Clean up listeners** when disposing widgets

### Example Widget Integration

```dart
class ProjectListWidget extends StatelessWidget {
  final CrudService _crudService = CrudService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Project>>(
      stream: _crudService.getProjectsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }
        
        final projects = snapshot.data!;
        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ProjectCard(project: project);
          },
        );
      },
    );
  }
}
```

---

## Error Handling

```dart
try {
  await crudService.deleteClient(clientId);
} catch (e) {
  if (e.toString().contains('linked to this client')) {
    // Show user-friendly message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cannot Delete Client'),
        content: Text('This client has active projects.'),
      ),
    );
  }
}
```

---

## Performance Tips

1. Use `getProjectsStream()` once and share the stream
2. Implement pagination for large lists
3. Use `bulkUpdateProjectStatus()` instead of multiple individual updates
4. Cache frequently accessed data
5. Dispose of stream subscriptions properly

---

This guide covers all CRUD operations available in the app. For more details, check the source code in `lib/core/services/crud_service.dart`.
