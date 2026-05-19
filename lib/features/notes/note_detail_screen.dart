import 'package:flutter/material.dart';
class NoteDetailScreen extends StatelessWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Note')));
}
