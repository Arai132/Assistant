import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/item_provider.dart';
import '../../providers/sync_provider.dart';
import 'widgets/note_list_tile.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final allNotes = ref.watch(notesProvider).valueOrNull ?? [];
    final syncQueue = ref.watch(syncQueueProvider);
    final notes = _query.isEmpty
        ? allNotes
        : allNotes.where((n) =>
            n.title.toLowerCase().contains(_query.toLowerCase()) ||
            n.body.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search notes...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (ctx, i) => NoteListTile(
          item: notes[i],
          onTap: () => context.push('/notes/${notes[i].id}'),
          isPendingSync: syncQueue.hasPending(notes[i].id),
        ),
      ),
    );
  }
}
