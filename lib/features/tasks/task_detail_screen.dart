import 'package:flutter/material.dart';
class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Task')));
}
