import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../content/content_coordinator.dart';
import '../data/content_repository.dart';
import '../l10n/app_strings.dart';
import 'home_page.dart';
import 'practice_page.dart';
import 'profile_page.dart';
import 'progress_page.dart';
import 'subjects_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.contentRepository,
    this.contentCoordinator,
    this.appController,
  });

  final ContentRepository contentRepository;

  /// Optional content pipeline coordinator. When supplied, MainShell listens
  /// for repository swaps (assets → activated cache) and rebuilds the pages
  /// with the coordinator's current repository.
  final ContentCoordinator? contentCoordinator;
  final AppController? appController;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late ContentRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.contentCoordinator?.repository ??
        widget.contentRepository;
    widget.contentCoordinator?.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    widget.contentCoordinator?.removeListener(_onContentChanged);
    super.dispose();
  }

  void _onContentChanged() {
    final coordinator = widget.contentCoordinator;
    if (coordinator == null) {
      return;
    }
    setState(() {
      _repository = coordinator.repository;
    });
  }

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomePage(
            contentRepository: _repository,
            contentCoordinator: widget.contentCoordinator,
            onNavigateToTab: _selectTab,
          ),
          SubjectsPage(contentRepository: _repository),
          PracticePage(contentRepository: _repository),
          ProgressPage(contentRepository: _repository),
          ProfilePage(
            appController: widget.appController,
            contentCoordinator: widget.contentCoordinator,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: AppStrings.t(context, 'nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: AppStrings.t(context, 'nav_learn'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.edit_outlined),
            selectedIcon: const Icon(Icons.edit),
            label: AppStrings.t(context, 'nav_practice'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: AppStrings.t(context, 'nav_progress'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: AppStrings.t(context, 'nav_profile'),
          ),
        ],
      ),
    );
  }
}
