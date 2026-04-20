import 'package:go_router/go_router.dart';
import 'package:money_trace/features/auth/application/auth_controller.dart';
import 'package:money_trace/features/auth/presentation/auth_flow_screen.dart';
import 'package:money_trace/features/analytics/presentation/analytics_screen.dart';
import 'package:money_trace/features/ai_coach/presentation/ai_coach_screen.dart';
import 'package:money_trace/core/settings/app_settings_controller.dart';
import 'package:money_trace/features/finance/application/finance_controller.dart';
import 'package:money_trace/features/overview/presentation/overview_screen.dart';
import 'package:money_trace/features/settings/presentation/settings_screen.dart';
import 'package:money_trace/features/templates/presentation/templates_screen.dart';
import 'package:money_trace/features/transactions/presentation/activity_screen.dart';
import 'package:money_trace/ui/app_shell.dart';

GoRouter buildRouter({
  required AuthController authController,
  required FinanceController financeController,
  required AppSettingsController settingsController,
}) {
  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: authController,
    redirect: (context, state) {
      final isWelcomeRoute = state.matchedLocation == '/welcome';

      if (!authController.isAuthenticated) {
        return isWelcomeRoute ? null : '/welcome';
      }

      if (isWelcomeRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => AuthFlowScreen(
          authController: authController,
          financeController: financeController,
        ),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => ActivityScreen(
          controller: financeController,
          settingsController: settingsController,
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => OverviewScreen(
                  authController: authController,
                  controller: financeController,
                  settingsController: settingsController,
                ),
                routes: [
                  GoRoute(
                    path: 'settings',
                    builder: (context, state) => SettingsScreen(
                      controller: financeController,
                      settingsController: settingsController,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/templates',
                builder: (context, state) => TemplatesScreen(
                  controller: financeController,
                  settingsController: settingsController,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => AnalyticsScreen(
                  controller: financeController,
                  settingsController: settingsController,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/coach',
                builder: (context, state) =>
                    AiCoachScreen(controller: financeController),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
