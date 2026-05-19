import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/app_database.dart';
import '../../providers/attachment_provider.dart';
import '../../providers/database_provider.dart';

class AttachmentSection extends ConsumerWidget {
  final String itemId;
  const AttachmentSection({super.key, required this.itemId});

  Future<void> _delete(BuildContext context, WidgetRef ref, Attachment att) async {
    await ref.read(attachmentRepositoryProvider).deleteAttachment(att.id, att.localPath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachmentsAsync = ref.watch(attachmentsForItemProvider(itemId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        attachmentsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('Error: $e'),
          data: (list) {
            final voices = list.where((a) => a.type == AttachmentType.voiceMemo).toList();
            final others = list.where((a) => a.type != AttachmentType.voiceMemo).toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...voices.map((att) => _VoiceMemoTile(attachment: att)),
                if (others.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: others.map((att) => _AttachmentChip(
                      attachment: att,
                      onDelete: () => _delete(context, ref, att),
                    )).toList(),
                  ),
                if (list.isEmpty)
                  const Text('No attachments yet.',
                      style: TextStyle(color: Colors.grey)),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _VoiceMemoTile extends StatelessWidget {
  final Attachment attachment;
  const _VoiceMemoTile({required this.attachment});

  @override
  Widget build(BuildContext context) {
    final name = attachment.localPath.split('/').last;
    return ListTile(
      dense: true,
      leading: const Icon(Icons.mic),
      title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.play_arrow),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback onDelete;
  const _AttachmentChip({required this.attachment, required this.onDelete});

  IconData _iconFor(AttachmentType type) => switch (type) {
        AttachmentType.voiceMemo => Icons.mic,
        AttachmentType.image => Icons.image,
        AttachmentType.document => Icons.description,
        AttachmentType.video => Icons.videocam,
      };

  String _label() {
    final name = attachment.localPath.split('/').last;
    return name.length > 20 ? '${name.substring(0, 17)}...' : name;
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(_iconFor(attachment.type), size: 16),
      label: Text(_label()),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
    );
  }
}
