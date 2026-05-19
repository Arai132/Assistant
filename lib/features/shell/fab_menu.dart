import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/database_provider.dart';

class FabMenu extends ConsumerStatefulWidget {
  const FabMenu({super.key});

  @override
  ConsumerState<FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends ConsumerState<FabMenu> with SingleTickerProviderStateMixin {
  bool _open = false;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _open = !_open);
    _open ? _controller.forward() : _controller.reverse();
  }

  Future<void> _newTask() async {
    _toggle();
    final repo = ref.read(itemRepositoryProvider);
    final id = await repo.createTask(title: 'New task');
    if (mounted) context.push('/tasks/$id');
  }

  Future<void> _newNote() async {
    _toggle();
    final repo = ref.read(itemRepositoryProvider);
    final id = await repo.createNote(title: 'New note');
    if (mounted) context.push('/notes/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_open) ...[
          _FabOption(icon: Icons.task_alt, label: 'New Task', onTap: _newTask),
          const SizedBox(height: 8),
          _FabOption(icon: Icons.note_add, label: 'New Note', onTap: _newNote),
          const SizedBox(height: 8),
          _FabOption(icon: Icons.camera_alt, label: 'Snap Image', onTap: _toggle),
          const SizedBox(height: 8),
          _FabOption(icon: Icons.mic, label: 'Record Voice', onTap: _toggle),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedIcon(icon: AnimatedIcons.add_event, progress: _controller),
        ),
      ],
    );
  }
}

class _FabOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _FabOption({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(width: 8),
        FloatingActionButton.small(onPressed: onTap, child: Icon(icon)),
      ],
    );
  }
}
