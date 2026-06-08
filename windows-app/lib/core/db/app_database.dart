import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Owns the SQLite (FFI) database connection and schema migrations.
///
/// Uses `sqflite_common_ffi` which works on Windows desktop without the
/// Android/iOS sqflite plugin.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static AppDatabase? _instance;
  static AppDatabase get instance {
    final i = _instance;
    if (i == null) throw StateError('AppDatabase not initialized.');
    return i;
  }

  static const _dbName = 'tubevault.db';
  static const _version = 1;

  static Future<AppDatabase> init() async {
    sqfliteFfiInit();
    final factory = databaseFactoryFfi;
    final supportDir = await getApplicationSupportDirectory();
    final path = p.join(supportDir.path, _dbName);
    if (!await Directory(supportDir.path).exists()) {
      await Directory(supportDir.path).create(recursive: true);
    }
    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _version,
        onCreate: _onCreate,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    return _instance = AppDatabase._(db);
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE downloads (
        id          TEXT PRIMARY KEY,
        url         TEXT NOT NULL,
        title       TEXT NOT NULL,
        type        TEXT NOT NULL,
        summary     TEXT,
        status      TEXT NOT NULL,
        output_dir  TEXT,
        file_path   TEXT,
        thumbnail_url TEXT,
        file_size   INTEGER,
        error       TEXT,
        created_at  INTEGER NOT NULL,
        completed_at INTEGER
      );
    ''');
    await db.execute(
        'CREATE INDEX idx_downloads_created ON downloads(created_at DESC);');
    await db
        .execute('CREATE INDEX idx_downloads_status ON downloads(status);');
  }
}
