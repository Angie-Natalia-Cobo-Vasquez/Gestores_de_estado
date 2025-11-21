import 'package:flutter/material.dart';
import 'src/config/theme.dart';
import 'src/ui/screens/home_screen.dart';

class TaskFlowApp extends StatelessWidget {
  const TaskFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
