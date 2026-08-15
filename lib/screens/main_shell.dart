import 'package:flutter/material.dart';

import '../data/content_repository.dart';
import 'home_page.dart';
import 'practice_page.dart';
import 'profile_page.dart';
import 'progress_page.dart';
import 'subjects_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.contentRepository,
  });

  final ContentRepository contentRepository;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    HomePage(
      contentRepository: widget.contentRepository,
      onNavigateToTab: _selectTab,
    ),
    SubjectsPage(contentRepository: widget.contentRepository),
    PracticePage(contentRepository: widget.contentRepository),
    ProgressPage(contentRepository: widget.contentRepository),
    const ProfilePage(),
  ];

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
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Progress',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
