import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'shared/widgets/app_scaffold.dart';

class KanbanBoardApp extends StatelessWidget {
  const KanbanBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KanbanBoard',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const AppScaffold(),
    );
  }
}
