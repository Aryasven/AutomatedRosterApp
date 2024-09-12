import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'rosters.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(
      '''
      CREATE TABLE rosters(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        rosterData TEXT
      )
      ''',
    );
  }

  Future<int> saveRoster(String name, Map<String, dynamic> roster) async {
    final db = await database;
    return await db.insert(
      'rosters',
      {
        'name': name,
        'rosterData': roster.toString(), // Convert to string
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRosters() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('rosters');
    
    return List.generate(maps.length, (i) {
      return {
        'id': maps[i]['id'],
        'name': maps[i]['name'],
        'rosterData': maps[i]['rosterData'],
      };
    });
  }
}
