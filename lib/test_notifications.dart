import 'package:flutter/material.dart';
import 'core/services/enhanced_notification_service.dart';

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
          const Text(
            '🔔 Test Notification Sounds',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap any button to test notification sounds. Make sure your device is not in silent mode!',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          _buildTestButton(
            context,
            icon: '🚨',
            title: 'Critical Alert',
            subtitle: 'Payment Overdue',
            color: Colors.red,
            onTap: () => EnhancedNotificationService.instance.notifyPaymentOverdue(
              projectName: 'Test Project',
              amount: 5000,
              daysOverdue: 5,
            ),
          ),
          
          _buildTestButton(
            context,
            icon: '💰',
            title: 'Payment Alert',
            subtitle: 'Payment Due',
            color: Colors.orange,
            onTap: () => EnhancedNotificationService.instance.notifyPaymentDue(
              projectName: 'Test Project',
              amount: 5000,
              dueDate: DateTime.now().add(const Duration(days: 3)),
            ),
          ),
          
          _buildTestButton(
            context,
            icon: '📋',
            title: 'Project Alert',
            subtitle: 'Deadline Approaching',
            color: Colors.amber,
            onTap: () => EnhancedNotificationService.instance.notifyProjectDeadline(
              projectName: 'Test Project',
              deadline: DateTime.now().add(const Duration(days: 3)),
              daysRemaining: 3,
            ),
          ),
          
          _buildTestButton(
            context,
            icon: '⏰',
            title: 'Task Reminder',
            subtitle: 'Don\'t forget!',
            color: Colors.blue,
            onTap: () => EnhancedNotificationService.instance.notifyTaskReminder(
              taskName: 'Complete documentation',
              projectName: 'Test Project',
            ),
          ),
          
          _buildTestButton(
            context,
            icon: '✅',
            title: 'Success',
            subtitle: 'Project Completed',
            color: Colors.green,
            onTap: () => EnhancedNotificationService.instance.notifyProjectCompleted(
              projectName: 'Test Project',
            ),
          ),
          
          _buildTestButton(
            context,
            icon: '💸',
            title: 'Finance Alert',
            subtitle: 'Budget Warning',
            color: Colors.teal,
            onTap: () => EnhancedNotificationService.instance.notifyBudgetWarning(
              projectName: 'Test Project',
              budget: 10000,
              spent: 8500,
              percentUsed: 85,
            ),
          ),
          
          _buildTestButton(
            context,
            icon: '📊',
            title: 'Daily Summary',
            subtitle: 'Your daily report',
            color: Colors.purple,
            onTap: () => EnhancedNotificationService.instance.notifyDailySummary(
              activeProjects: 5,
              tasksCompleted: 12,
              upcomingDeadlines: 3,
            ),
          ),
          
          _buildTestButton(
            context,
            icon: '🚀',
            title: 'Project Start',
            subtitle: 'Time to begin!',
            color: Colors.indigo,
            onTap: () => EnhancedNotificationService.instance.notifyProjectStart(
              projectName: 'Test Project',
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: () async {
              await EnhancedNotificationService.instance.cancelAllNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications cleared!')),
                );
              }
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear All Notifications'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context, {
    required String icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.notifications_active, color: color),
        onTap: () {
          onTap();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$title notification sent!'),
              duration: const Duration(seconds: 2),
              backgroundColor: color,
            ),
          );
        },
      ),
    );
  }
}
