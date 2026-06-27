import 'package:flutter/material.dart';
import 'package:devtrack/core/services/notification_service.dart';

/// Test screen to try out different notification sounds
class TestNotificationsScreen extends StatelessWidget {
  const TestNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Notifications'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTestCategory(
            context,
            'Critical Alerts',
            [
              _buildTestItem(
                context,
                icon: '🚨',
                title: 'Critical Alert',
                subtitle: 'Payment Overdue',
                color: Colors.red,
                onTap: () => AppNotificationService.instance.notifyPaymentOverdue(
                  projectName: 'Test Project',
                  amount: 5000,
                  daysOverdue: 5,
                ),
              ),
            ],
          ),
          _buildTestCategory(
            context,
            'Payment Notifications',
            [
              _buildTestItem(
                context,
                icon: '💰',
                title: 'Payment Due',
                subtitle: 'Upcoming Payment',
                color: Colors.green,
                onTap: () => AppNotificationService.instance.notifyPaymentDue(
                  projectName: 'Test Project',
                  amount: 2500,
                  dueDate: DateTime.now().add(const Duration(days: 2)),
                ),
              ),
            ],
          ),
          _buildTestCategory(
            context,
            'Project Notifications',
            [
              _buildTestItem(
                context,
                icon: '⏰',
                title: 'Project Deadline',
                subtitle: 'Approaching Deadline',
                color: Colors.orange,
                onTap: () => AppNotificationService.instance.notifyProjectDeadline(
                  projectName: 'Test Project',
                  deadline: DateTime.now().add(const Duration(days: 3)),
                  daysRemaining: 3,
                ),
              ),
            ],
          ),
          _buildTestCategory(
            context,
            'Task Reminders',
            [
              _buildTestItem(
                context,
                icon: '📋',
                title: 'Task Reminder',
                subtitle: 'Standard Reminder',
                color: Colors.blue,
                onTap: () => AppNotificationService.instance.notifyTaskReminder(
                  taskName: 'Submit Design',
                  projectName: 'Test Project',
                ),
              ),
            ],
          ),
          _buildTestCategory(
            context,
            'Success Notifications',
            [
              _buildTestItem(
                context,
                icon: '🎉',
                title: 'Project Completed',
                subtitle: 'Completion Celebration',
                color: Colors.purple,
                onTap: () => AppNotificationService.instance.notifyProjectCompleted(
                  projectName: 'Test Project',
                ),
              ),
            ],
          ),
          _buildTestCategory(
            context,
            'Finance Alerts',
            [
              _buildTestItem(
                context,
                icon: '⚠️',
                title: 'Budget Warning',
                subtitle: 'Budget Threshold Reached',
                color: Colors.amber,
                onTap: () => AppNotificationService.instance.notifyBudgetWarning(
                  projectName: 'Test Project',
                  budget: 10000,
                  spent: 8500,
                  percentUsed: 85,
                ),
              ),
            ],
          ),
          _buildTestCategory(
            context,
            'Summaries',
            [
              _buildTestItem(
                context,
                icon: '📊',
                title: 'Daily Summary',
                subtitle: 'Daily Update',
                color: Colors.teal,
                onTap: () => AppNotificationService.instance.notifyDailySummary(
                  activeProjects: 3,
                  tasksCompleted: 5,
                  upcomingDeadlines: 1,
                ),
              ),
            ],
          ),
          _buildTestCategory(
            context,
            'Project Start',
            [
              _buildTestItem(
                context,
                icon: '🚀',
                title: 'Project Start',
                subtitle: 'Starting Today',
                color: Colors.indigo,
                onTap: () => AppNotificationService.instance.notifyProjectStart(
                  projectName: 'New Launch',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await AppNotificationService.instance.cancelAllNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cancelled')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
            ),
            child: const Text('Cancel All Notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestCategory(BuildContext context, String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        ...items,
        const Divider(),
      ],
    );
  }

  Widget _buildTestItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Text(icon, style: const TextStyle(fontSize: 20)),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.play_circle_fill, color: Colors.grey),
      onTap: onTap,
    );
  }
}
