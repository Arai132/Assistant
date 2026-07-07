import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../data/database/app_database.dart';

class ExportService {
  final AppDatabase _db;
  ExportService(this._db);

  Future<String> exportAsJson({Directory? directory}) async {
    final items = await _db.select(_db.items).get();
    final tasks = await _db.select(_db.tasks).get();
    final attachments = await _db.select(_db.attachments).get();

    final json = jsonEncode({
      'exportedAt': DateTime.now().toIso8601String(),
      'items': items.map(_itemToJson).toList(),
      'tasks': tasks.map(_taskToJson).toList(),
      'attachments': attachments.map(_attachmentToJson).toList(),
    });

    final dir = directory ?? await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'assistant_export_$timestamp.json'));
    await file.writeAsString(json);
    return file.path;
  }

  Map<String, dynamic> _itemToJson(Item item) => {
        'id': item.id,
        'title': item.title,
        'body': item.body,
        'type': item.type.name,
        'createdAt': item.createdAt.toIso8601String(),
        'updatedAt': item.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _taskToJson(TaskRow task) => {
        'id': task.id,
        'priority': task.priority.name,
        'dueDate': task.dueDate?.toIso8601String(),
        'status': task.status.name,
        'calendarEventId': task.calendarEventId,
      };

  Map<String, dynamic> _attachmentToJson(Attachment att) => {
        'id': att.id,
        'itemId': att.itemId,
        'type': att.type.name,
        'localPath': att.localPath,
        'cloudUrl': att.cloudUrl,
        'ocrText': att.ocrText,
        'aiDescription': att.aiDescription,
        'createdAt': att.createdAt.toIso8601String(),
      };
}
