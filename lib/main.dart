import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_controller.dart';
import 'app/app_scope.dart';
import 'app/app_theme.dart';
import 'config/app_constants.dart';
import 'config/feature_flags.dart';
import 'content/app_content_manager.dart';
import 'content/content_coordinator.dart';
import 'data/content_repository.dart';
import 'data/json_content_repository.dart';
import 'screens/main_shell.dart';
import 'screens/student_profile_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appController = AppController();
  final coordinator = ContentCoordinator(
    manager: AppContentManager(assets: JsonContentRepository()),
  );
  await Future.wait([
    appController.initialize(),
    coordinator.initialize(),
  ]);

  // Boot first, sync in the background: an unreachable remote or a rejected
  // update never blocks the UI or throws on startup.
  if (FeatureFlags.remoteContentSync) {
    unawaited(coordinator.syncNow());
  }

  runApp(
    StudyApp(
      appController: appController,
      contentCoordinator: coordinator,
    ),
  );
}

class StudyApp extends StatefulWidget {
  const StudyApp({
    super.key,
    this.appController,
    this.contentRepository,
    this.contentCoordinator,
  });

  final AppController? appController;

  /// Optional repository override (used by tests). Defaults to the local
  /// JSON asset repository.
  final ContentRepository? contentRepository;

  /// Optional content pipeline coordinator. When supplied, its current
  /// repository backs the app and its status is surfaced on the Home screen.
  final ContentCoordinator? contentCoordinator;

  @override
  State<StudyApp> createState() => _StudyAppState();
}

class _StudyAppState extends State<StudyApp> {
  late final AppController _appController;
  late final bool _ownsAppController;
  late final ContentRepository _repository;

  @override
  void initState() {
    super.initState();
    _ownsAppController = widget.appController == null;
    _appController = widget.appController ?? AppController();
    final coordinator = widget.contentCoordinator;
    _repository = coordinator?.repository ??
        widget.contentRepository ??
        JsonContentRepository();
  }

  @override
  void dispose() {
    if (_ownsAppController) {
      _appController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appController,
      builder: (context, child) {
        return AppScope(
          controller: _appController,
          child: MaterialApp(
            title: AppConstants.appDisplayName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: _appController.themeMode,
            locale: Locale(_appController.languageCode),
            supportedLocales: const [
              Locale('fr'),
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: FeatureFlags.onboarding && _appController.needsOnboarding
                ? StudentProfilePage(controller: _appController)
                : MainShell(
                    contentRepository: _repository,
                    contentCoordinator: widget.contentCoordinator,
                    appController: _appController,
                  ),
          ),
        );
      },
    );
  }
}
