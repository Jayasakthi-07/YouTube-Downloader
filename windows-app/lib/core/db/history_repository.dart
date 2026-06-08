import 'package:sqflite_common_ffi/sqflite_ffi.dart' show ConflictAlgorithm;

import '../models/app_enums.dart';
import '../models/download_options.dart';
import '../models/download_task.dart';
import 'app_database.dart';

/// How history/file lists can be ordered.
enum HistorySort { dateDesc, dateAsc, nameAsc, sizeDesc }

/// CRUD access to the `downloads` table (history + persisted queue records).
class HistoryRepository {
  HistoryRepository(this._db);
  final AppDatabase _db;

  Future<void> upsert(DownloadTask task) async {
    await _db.db.insert(
      'downloads',
      task.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStatus(String id, TaskStatus status,
      {String? filePath, int? size, String? error}) async {
    final values = <String, Object?>{
      'status': status.name,
      'file_path': ?filePath,
      'file_size': ?size,
      'error': ?error,
      if (status == TaskStatus.completed)
        'completed_at': DateTime.now().millisecondsSinceEpoch,
    };
    await _db.db.update('downloads', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(String id) async {
    await _db.db.delete('downloads', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clearAll() async {
    await _db.db.delete('downloads');
  }

  /// Returns history rows, optionally filtered/sorted/searched.
  Future<List<DownloadTask>> query({
    String? search,
    DownloadType? type,
    TaskStatus? status,
    HistorySort sort = HistorySort.dateDesc,
  }) async {
    final where = <String>[];
    final args = <Object?>[];
    if (search != null && search.trim().isNotEmpty) {
      where.add('title LIKE ?');
      args.add('%${search.trim()}%');
    }
    if (type != null) {
      where.add('type = ?');
      args.add(type.name);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }

    final orderBy = switch (sort) {
      HistorySort.dateDesc => 'created_at DESC',
      HistorySort.dateAsc => 'created_at ASC',
      HistorySort.nameAsc => 'title COLLATE NOCASE ASC',
      HistorySort.sizeDesc => 'file_size DESC',
    };

    final rows = await _db.db.query(
      'downloads',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: orderBy,
    );
    return rows.map(_fromRow).toList();
  }

  /// Tasks that were interrupted (downloading/paused/queued) — for auto-resume.
  Future<List<DownloadTask>> interrupted() async {
    final rows = await _db.db.query(
      'downloads',
      where: 'status IN (?, ?, ?, ?)',
      whereArgs: [
        TaskStatus.downloading.name,
        TaskStatus.paused.name,
        TaskStatus.queued.name,
        TaskStatus.fetching.name,
      ],
      orderBy: 'created_at ASC',
    );
    return rows.map(_fromRow).toList();
  }

  DownloadTask _fromRow(Map<String, Object?> r) {
    final type = DownloadType.values.firstWhere(
      (t) => t.name == r['type'],
      orElse: () => DownloadType.video,
    );
    return DownloadTask(
      id: r['id'] as String,
      url: r['url'] as String,
      title: r['title'] as String,
      options: DownloadOptions(type: type),
      status: TaskStatus.values.firstWhere(
        (s) => s.name == r['status'],
        orElse: () => TaskStatus.queued,
      ),
      outputDir: r['output_dir'] as String?,
      filePath: r['file_path'] as String?,
      thumbnailUrl: r['thumbnail_url'] as String?,
      fileSizeBytes: (r['file_size'] as num?)?.toInt(),
      error: r['error'] as String?,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch((r['created_at'] as num).toInt()),
      completedAt: r['completed_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              (r['completed_at'] as num).toInt()),
    );
  }
}
