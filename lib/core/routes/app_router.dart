import 'package:flutter/material.dart';

// Feature modules
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/projects/screens/projects_screen.dart';
import '../../features/projects/screens/project_detail_screen.dart';
import '../../features/projects/screens/add_edit_project_screen.dart';
import '../../features/analytics/screens/analytics_screen.dart';
import '../../features/finance/screens/finance_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/notifications/screens/notification_settings_screen.dart';
import '../../features/export/screens/export_screen.dart';


class AppRoutes {
  // Auth & Onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  
  // Main Navigation (Bottom Nav)
  static const String home = '/home';
  static const String projects = '/projects';
  static const String analytics = '/analytics';
  static const String settings = '/settings';
  
  // Aliases for compatibility
  static const String dashboard = home;
  static const String createTask = addEditProject;
  
  // Project Management
  static const String projectDetail = '/project-detail';
  static const String addEditProject = '/add-edit-project';
  
  // Additional Features
  static const String finance = '/finance';
  static const String notifications = '/notifications';
  static const String notificationSettings = '/notification-settings';
  static const String export = '/export';
  static const String clientBook = '/client-book';
}

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);
      case AppRoutes.onboarding:
        return _buildRoute(const OnboardingScreen(), settings);
      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings);
      case AppRoutes.signup:
        return _buildRoute(const SignupScreen(), settings);
      
      case AppRoutes.home:
        return _buildRoute(const DashboardScreen(), settings, fade: true);
      case AppRoutes.projects:
        return _buildRoute(const ProjectsScreen(), settings);
      case AppRoutes.analytics:
        return _buildRoute(const AnalyticsScreen(), settings);
      case AppRoutes.settings:
        return _buildRoute(const SettingsScreen(), settings);
      
      case AppRoutes.projectDetail:
        final projectId = settings.arguments is String ? settings.arguments as String : '';
        return _buildRoute(ProjectDetailScreen(projectId: projectId), settings);
      
      case AppRoutes.addEditProject:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(
          AddEditProjectScreen(projectId: args?['projectId']),
          settings,
          slide: true,
        );
      
      case AppRoutes.finance:
        return _buildRoute(const FinanceScreen(), settings);
      case AppRoutes.notifications:
        return _buildRoute(const NotificationsScreen(), settings);
      case AppRoutes.notificationSettings:
        return _buildRoute(const NotificationSettingsScreen(), settings, slide: true);
      case AppRoutes.export:
        return _buildRoute(const ExportScreen(), settings);

      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  static PageRoute _buildRoute(Widget page, RouteSettings settings, {bool fade = false, bool slide = false}) {
    if (fade) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      );
    }
    if (slide) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      );
    }
    return MaterialPageRoute(settings: settings, builder: (_) => page);
  }
}
