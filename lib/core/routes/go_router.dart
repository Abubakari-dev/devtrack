import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:devtrack/features/auth/screens/login_screen.dart';
import 'package:devtrack/features/auth/screens/signup_screen.dart';
import 'package:devtrack/features/dashboard/screens/dashboard_screen.dart';
import 'package:devtrack/features/projects/screens/projects_screen.dart';
import 'package:devtrack/features/finance/screens/wallets/wallets_screen.dart';
import 'package:devtrack/features/finance/screens/transactions/transactions_screen.dart';
import 'package:devtrack/features/finance/screens/transactions/add_transaction_screen.dart';
import 'package:devtrack/features/settings/screens/settings_screen.dart';

import 'package:devtrack/features/analytics/screens/analytics_screen.dart';
import 'package:devtrack/features/projects/screens/tasks_screen.dart';
import 'package:devtrack/features/notifications/screens/notifications_screen.dart';
import 'package:devtrack/features/export/screens/export_screen.dart';
import 'package:devtrack/features/finance/screens/overview/finance_screen.dart';
import 'package:devtrack/features/finance/screens/debts/debts_screen.dart';
import 'package:devtrack/features/finance/screens/debts/add_debt_screen.dart';
import 'package:devtrack/features/finance/screens/debts/debt_details_screen.dart';
import 'package:devtrack/features/finance/screens/budgets/budgets_screen.dart';
import 'package:devtrack/features/finance/screens/budgets/add_budget_screen.dart';
import '../database/app_database.dart';

import 'package:devtrack/features/projects/screens/project_detail_screen.dart';
import 'package:devtrack/features/projects/screens/add_edit_project_screen.dart';
import 'package:devtrack/features/finance/screens/expenses/all_expenses_screen.dart';
import 'package:devtrack/features/finance/screens/expenses/add_expense_screen.dart';
import 'package:devtrack/features/finance/screens/wallets/transfer_money_screen.dart';
import 'package:devtrack/features/settings/screens/features_screen.dart';
import 'package:devtrack/features/onboarding/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/security_service.dart';

final goRouterStateProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final prefs = await SharedPreferences.getInstance();
      final bool isFirstTime = prefs.getBool('is_first_time') ?? true;

      if (isFirstTime && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      }

      final user = FirebaseAuth.instance.currentUser;
      final bool loggingIn = state.matchedLocation == '/login' || 
                           state.matchedLocation == '/signup' || 
                           state.matchedLocation == '/onboarding';

      if (!isFirstTime && user == null) {
        return loggingIn && state.matchedLocation != '/onboarding' ? null : '/login';
      }

      if (user != null && loggingIn) {
        return '/';
      }

      // Biometric protection for Finance
      final isFinanceRoute = state.matchedLocation.startsWith('/finance') ||
          state.matchedLocation.startsWith('/wallets') ||
          state.matchedLocation.startsWith('/transactions') ||
          state.matchedLocation.startsWith('/debts') ||
          state.matchedLocation.startsWith('/add-debt') ||
          state.matchedLocation.startsWith('/add-transaction') ||
          state.matchedLocation.startsWith('/budgets') ||
          state.matchedLocation.startsWith('/add-budget') ||
          state.matchedLocation.startsWith('/expenses') ||
          state.matchedLocation.startsWith('/add-expense');

      if (isFinanceRoute) {
        final isBiometricEnabled = await SecurityService.instance.isBiometricEnabled;
        if (isBiometricEnabled && !SecurityService.instance.isFinanceUnlocked) {
          final authenticated = await SecurityService.instance.authenticate(
            reason: 'Authenticate to access Finance Hub',
          );
          if (authenticated) {
            SecurityService.instance.unlockFinance();
            return null;
          } else {
            return '/'; // Go back to dashboard if cancelled
          }
        }
      } else {
        // If we move away from finance, lock it again
        SecurityService.instance.lockFinance();
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              selectedItemColor: const Color(0xFF6366F1), // AppColors.indigo
              unselectedItemColor: Colors.grey,
              showUnselectedLabels: true,
              currentIndex: _calculateSelectedIndex(state.fullPath ?? '/'),
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/');
                    break;
                  case 1:
                    context.go('/projects');
                    break;
                  case 2:
                    context.go('/finance');
                    break;
                  case 3:
                    context.go('/analytics');
                    break;
                  case 4:
                    context.go('/settings');
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.folder_open_rounded),
                  label: 'Projects',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  activeIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Finance',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.insights_rounded),
                  label: 'Analytics',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings_rounded),
                  label: 'Settings',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/project-detail',
            builder: (context, state) {
              final projectId = state.extra as String;
              return ProjectDetailScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/add-project',
            builder: (context, state) => const AddEditProjectScreen(),
          ),
          GoRoute(
            path: '/edit-project',
            builder: (context, state) {
              final projectId = state.extra as String;
              return AddEditProjectScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/features',
            builder: (context, state) => const FeaturesScreen(),
          ),
          // Sub-pages
          GoRoute(
            path: '/wallets',
            builder: (context, state) => const WalletsScreen(),
          ),
          GoRoute(
            path: '/finance',
            builder: (context, state) => const FinanceScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const AllExpensesScreen(),
          ),
          GoRoute(
            path: '/add-expense',
            builder: (context, state) => const AddExpenseScreen(),
          ),
          GoRoute(
            path: '/transfer',
            builder: (context, state) => const TransferMoneyScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/export',
            builder: (context, state) => const ExportScreen(),
          ),
          GoRoute(
            path: '/add-transaction',
            builder: (context, state) {
              final walletId = state.extra as String?;
              return AddTransactionScreen(initialWalletId: walletId);
            },
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: '/debts',
            builder: (context, state) => const DebtsScreen(),
          ),
          GoRoute(
            path: '/add-debt',
            builder: (context, state) => const AddDebtScreen(),
          ),
          GoRoute(
            path: '/debt-details',
            builder: (context, state) {
              final debt = state.extra as Debt;
              return DebtDetailsScreen(debt: debt);
            },
          ),
          GoRoute(
            path: '/budgets',
            builder: (context, state) => const BudgetsScreen(),
          ),
          GoRoute(
            path: '/add-budget',
            builder: (context, state) => const AddBudgetScreen(),
          ),
        ],
      ),
    ],
  );
});

int _calculateSelectedIndex(String path) {
  if (path == '/') return 0;
  if (path.startsWith('/projects')) return 1;
  if (path.startsWith('/finance') || 
      path.startsWith('/wallets') || 
      path.startsWith('/transactions') || 
      path.startsWith('/debts') ||
      path.startsWith('/add-debt') ||
      path.startsWith('/add-transaction') ||
      path.startsWith('/budgets') ||
      path.startsWith('/add-budget') ||
      path.startsWith('/expenses') ||
      path.startsWith('/add-expense')) return 2;
  if (path.startsWith('/analytics')) return 3;
  if (path.startsWith('/settings')) return 4;
  return 0;
}
