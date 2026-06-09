import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/sync_providers.dart';

class SuqApp extends ConsumerStatefulWidget {
  const SuqApp({super.key});

  @override
  ConsumerState<SuqApp> createState() => _SuqAppState();
}

class _SuqAppState extends ConsumerState<SuqApp> with WidgetsBindingObserver {
  late final appRouter = createRouter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Instantiate the sync scheduler: runs an initial cold-start sync and
    // starts the connectivity/backstop/login triggers for the session.
    ref.read(syncSchedulerProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Drain any pending writes whenever the app returns to the foreground.
    if (state == AppLifecycleState.resumed) {
      ref.read(syncSchedulerProvider).syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
    );
  }
}
