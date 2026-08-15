import 'package:flutter/material.dart';

import 'app/app_theme.dart';
import 'data/content_repository.dart';
import 'data/json_content_repository.dart';
import 'screens/main_shell.dart';

void main() {
  runApp(const StudyApp());
}

class StudyApp extends StatefulWidget {
  const StudyApp({super.key, this.contentRepository});

  /// Optional repository override (used by tests). Defaults to the local
  /// JSON asset repository.
  final ContentRepository? contentRepository;

  @override
  State<StudyApp> createState() => _StudyAppState();
}

class _StudyAppState extends State<StudyApp> {
  late final ContentRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.contentRepository ?? JsonContentRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY Algeria BAC',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: MainShell(contentRepository: _repository),
    );
  }
}
