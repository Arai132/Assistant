import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';

class NoteListTile extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;
  final bool isPendingSync;

  const NoteListTile({
    super.key,
    required this.item,
    required this.onTap,
    this.isPendingSync = false,
  });

  static final _dateFmt = DateFormat.MMMd();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.note),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: item.body.isNotEmpty
          ? Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPendingSync)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
                semanticLabel: 'Pending sync',
              ),
            ),
          Text(
            _dateFmt.format(item.updatedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
