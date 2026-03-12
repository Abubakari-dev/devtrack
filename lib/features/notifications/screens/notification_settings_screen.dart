import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/notification_permission_handler.dart';
import '../../../core/services/enhanced_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _permissionHandler = NotificationPermissionHandler.instance;
  final _notificationService = EnhancedNotificationService.instance;
  
  bool _isLoading = true;
  NotificationPermissionStatus _permissionStatus = NotificationPermissionStatus.notDetermined;
  
  // Notification preferences
  bool _projectNotifications = true;
  bool _paymentNotifications = true;
  bool _taskReminders = true;
  bool _budgetAlerts = true;
  bool _dailySummary = true;
  bool _milestoneAlerts = true;
  bool _overdueAlerts = true;
  bool _successNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final status = await _permissionHandler.checkPermissionStatus();
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _permissionStatus = status;
      _projectNotifications = prefs.getBool('notif_projects') ?? true;
      _paymentNotifications = prefs.getBool('notif_payments') ?? true;
      _taskReminders = prefs.getBool('notif_tasks') ?? true;
      _budgetAlerts = prefs.getBool('notif_budget') ?? true;
      _dailySummary = prefs.getBool('notif_daily_summary') ?? true;
      _milestoneAlerts = prefs.getBool('notif_milestones') ?? true;
      _overdueAlerts = prefs.getBool('notif_overdue') ?? true;
      _successNotifications = prefs.getBool('notif_success') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _requestPermission() async {
    if (!mounted) return;
    
    final granted = await _permissionHandler.requestPermissions(
      context: context,
      showRationale: true,
    );
    
    if (granted) {
      setState(() {
        _permissionStatus = NotificationPermissionStatus.granted;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Notifications enabled successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showNotification(
      type: NotificationType.general,
      title: '🔔 Test Notification',
      body: 'This is a test notification from DevTrack!',
      payload: 'test',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F2328) : AppColors.surface,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2D333B) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification Settings',
          style: AppTextStyles.titleLarge(context).copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Permission Status Card
          _buildPermissionStatusCard(isDark),
          const SizedBox(height: 24),
          
          // Notification Categories
          _buildSectionTitle('Notification Categories', isDark),
          const SizedBox(height: 12),
          
          _buildNotificationToggle(
            icon: Icons.work_outline,
            title: 'Project Notifications',
            subtitle: 'Deadlines, start dates, and updates',
            value: _projectNotifications,
            color: AppColors.indigo,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _projectNotifications = value);
              _saveSetting('notif_projects', value);
            },
          ),
          
          _buildNotificationToggle(
            icon: Icons.payment,
            title: 'Payment Notifications',
            subtitle: 'Payment due dates and reminders',
            value: _paymentNotifications,
            color: AppColors.red,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _paymentNotifications = value);
              _saveSetting('notif_payments', value);
            },
          ),
          
          _buildNotificationToggle(
            icon: Icons.task_alt,
            title: 'Task Reminders',
            subtitle: 'Task and subtask reminders',
            value: _taskReminders,
            color: AppColors.blue,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _taskReminders = value);
              _saveSetting('notif_tasks', value);
            },
          ),
          
          _buildNotificationToggle(
            icon: Icons.account_balance_wallet,
            title: 'Budget Alerts',
            subtitle: 'Budget warnings and expense tracking',
            value: _budgetAlerts,
            color: AppColors.green,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _budgetAlerts = value);
              _saveSetting('notif_budget', value);
            },
          ),
          
          _buildNotificationToggle(
            icon: Icons.flag,
            title: 'Milestone Alerts',
            subtitle: 'Milestone achievements and approaching dates',
            value: _milestoneAlerts,
            color: AppColors.purple,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _milestoneAlerts = value);
              _saveSetting('notif_milestones', value);
            },
          ),
          
          _buildNotificationToggle(
            icon: Icons.warning_amber_rounded,
            title: 'Overdue Alerts',
            subtitle: 'Critical alerts for overdue items',
            value: _overdueAlerts,
            color: AppColors.orange,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _overdueAlerts = value);
              _saveSetting('notif_overdue', value);
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionTitle('Summary & Reports', isDark),
          const SizedBox(height: 12),
          
          _buildNotificationToggle(
            icon: Icons.summarize,
            title: 'Daily Summary',
            subtitle: 'Daily productivity reports at 8 PM',
            value: _dailySummary,
            color: AppColors.teal,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _dailySummary = value);
              _saveSetting('notif_daily_summary', value);
            },
          ),
          
          _buildNotificationToggle(
            icon: Icons.celebration,
            title: 'Success Notifications',
            subtitle: 'Completion and achievement alerts',
            value: _successNotifications,
            color: AppColors.green,
            isDark: isDark,
            onChanged: (value) {
              setState(() => _successNotifications = value);
              _saveSetting('notif_success', value);
            },
          ),
          
          const SizedBox(height: 24),
          
          // Test Notification Button
          if (_permissionStatus == NotificationPermissionStatus.granted)
            ElevatedButton.icon(
              onPressed: _testNotification,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Send Test Notification'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // View Pending Notifications
          OutlinedButton.icon(
            onPressed: _viewPendingNotifications,
            icon: const Icon(Icons.schedule),
            label: const Text('View Scheduled Notifications'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionStatusCard(bool isDark) {
    final isGranted = _permissionStatus == NotificationPermissionStatus.granted;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D333B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted ? AppColors.green : AppColors.orange,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isGranted ? Icons.check_circle : Icons.notifications_off,
            size: 48,
            color: isGranted ? AppColors.green : AppColors.orange,
          ),
          const SizedBox(height: 12),
          Text(
            isGranted ? 'Notifications Enabled' : 'Notifications Disabled',
            style: AppTextStyles.titleMedium(context).copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isGranted
                ? 'You will receive important updates and reminders'
                : 'Enable notifications to stay updated on your projects',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium(context).copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
          if (!isGranted) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.notifications_active),
              label: const Text('Enable Notifications'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTextStyles.titleMedium(context).copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNotificationToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D333B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge(context).copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall(context).copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: _permissionStatus == NotificationPermissionStatus.granted
                ? onChanged
                : null,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Future<void> _viewPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scheduled Notifications'),
        content: pending.isEmpty
            ? const Text('No scheduled notifications')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pending.length,
                  itemBuilder: (context, index) {
                    final notif = pending[index];
                    return ListTile(
                      leading: const Icon(Icons.schedule),
                      title: Text(notif.title ?? 'Notification'),
                      subtitle: Text(notif.body ?? ''),
                      dense: true,
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
