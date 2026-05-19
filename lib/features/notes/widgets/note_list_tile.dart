import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/database/app_database.dart';

class NoteListTile extends StatelessWidget {
  final Item item;
  final VoidCallback onTap;

  const NoteListTile({super.key, required this.item, required this.onTap});

  static final _dateFmt = DateFormat.MMMd();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.note),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: item.body.isNotEmpty
          ? Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Text(
        _dateFmt.format(item.updatedAt),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      onTap: onTap,
    );
  }
}
