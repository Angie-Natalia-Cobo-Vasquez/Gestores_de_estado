import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import '../../config/constants.dart';

class DBHelper {
  static Database? _db;
  static final DBHelper instance = DBHelper._internal();

  DBHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;

    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      _db = await factory.openDatabase(
        kDbName,
        options: OpenDatabaseOptions(
          version: kDbVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } else {
      final path = await getDatabasesPath();
      final dbPath = join(path, kDbName);
      _db = await openDatabase(
        dbPath,
        version: kDbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    }
    return _db!;
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE queue_operations (
        id TEXT PRIMARY KEY,
        entity TEXT,
        entity_id TEXT,
        op TEXT,
        payload TEXT,
        created_at INTEGER,
        attempt_count INTEGER DEFAULT 0,
        last_error TEXT,
        synced_at INTEGER
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE queue_operations ADD COLUMN synced_at INTEGER');
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
  }
}
