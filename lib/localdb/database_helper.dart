import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('history.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE History (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        table_data TEXT
      )
    ''');
  }

  Future<void> addHistoryRecord(String timestamp, String tableData) async {
    final db = await instance.database;

    await db.insert(
      'History',
      {'timestamp': timestamp, 'table_data': tableData},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getAllHistory() async {
    final db = await instance.database;
    return await db.query('History', orderBy: 'id DESC');
  }

  Future<void> clearHistory() async {
    final db = await instance.database;
    await db.delete('History');
  }
}
