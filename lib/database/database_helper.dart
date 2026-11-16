import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/contact.dart';

/// Singleton wrapper around the local SQLite database.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'contacts.db';
  static const _dbVersion = 1;
  static const table = 'contacts';

  Database? _database;

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = join(await getDatabasesPath(), _dbName);
    return openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $table (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            address TEXT NOT NULL,
            isFavorite INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
    );
  }

  // CREATE
  Future<int> insertContact(Contact contact) async {
    final db = await database;
    return db.insert(table, contact.toMap());
  }

  // READ (with optional name search and favorites filter)
  Future<List<Contact>> getContacts({
    String query = '',
    bool favoritesOnly = false,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object>[];

    if (query.trim().isNotEmpty) {
      where.add('name LIKE ?');
      args.add('%${query.trim()}%');
    }
    if (favoritesOnly) {
      where.add('isFavorite = 1');
    }

    final rows = await db.query(
      table,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Contact.fromMap).toList();
  }

  // UPDATE
  Future<int> updateContact(Contact contact) async {
    final db = await database;
    return db.update(
      table,
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> toggleFavorite(Contact contact) {
    return updateContact(contact.copyWith(isFavorite: !contact.isFavorite));
  }

  // DELETE
  Future<int> deleteContact(int id) async {
    final db = await database;
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }
}
