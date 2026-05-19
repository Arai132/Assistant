import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/database_provider.dart';
import '../shared/attachment_section.dart';

class NoteDetailScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends ConsumerState<NoteDetailScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _bodyCtrl = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final item = await ref.read(databaseProvider).itemsDao.getItemById(widget.noteId);
    if (mounted) {
      setState(() {
        _titleCtrl.text = item?.title ?? '';
        _bodyCtrl.text = item?.body ?? '';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final db = ref.read(databaseProvider);
    final title = _titleCtrl.text.trim();
    if (title.isNotEmpty) {
      await db.itemsDao.updateItemTitle(widget.noteId, title);
    }
    await db.itemsDao.updateItemBody(widget.noteId, _bodyCtrl.text);
  }

  Future<void> _promoteToTask() async {
    await ref.read(itemRepositoryProvider).promoteNoteToTask(widget.noteId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promoted to task')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleCtrl,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(border: InputBorder.none, hintText: 'Note title'),
          onEditingComplete: _save,
        ),
        actions: [
          TextButton(onPressed: _promoteToTask, child: const Text('Make Task')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: TextField(
                controller: _bodyCtrl,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Write your note...',
                  border: InputBorder.none,
                ),
                onEditingComplete: _save,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
            const Divider(),
            AttachmentSection(itemId: widget.noteId),
          ],
        ),
      ),
    );
  }
}
