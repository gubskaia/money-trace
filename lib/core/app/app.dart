import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:money_trace/core/app/app_dependencies.dart';
import 'package:money_trace/core/navigation/app_router.dart';
import 'package:money_trace/core/theme/app_theme.dart';
import 'package:money_trace/core/widgets/desktop_phone_frame.dart';

class MoneyTraceApp extends StatelessWidget {
  const MoneyTraceApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        dependencies.settingsController,
        dependencies.authController,
      ]),
      builder: (context, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'MoneyTrace',
          theme: AppTheme.light(
            preset: dependencies.settingsController.themePreset,
          ),
          scrollBehavior: const _MoneyTraceScrollBehavior(),
          builder: (context, child) {
            return DesktopPhoneFrame(child: child ?? const SizedBox.shrink());
          },
          routerConfig: buildRouter(
            authController: dependencies.authController,
            financeController: dependencies.financeController,
            settingsController: dependencies.settingsController,
          ),
          locale: const Locale('en', 'US'),
        );
      },
    );
  }
}

class _MoneyTraceScrollBehavior extends MaterialScrollBehavior {
  const _MoneyTraceScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.unknown,
  };
}
