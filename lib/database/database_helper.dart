import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'curome.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE mood_entries (
            id TEXT PRIMARY KEY,
            patient_id TEXT,
            date TEXT,
            mood INTEGER,
            label TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE reminders (
            id TEXT PRIMARY KEY,
            type TEXT,
            label TEXT,
            time TEXT,
            confirmed INTEGER DEFAULT 0,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE appointments (
            id TEXT PRIMARY KEY,
            title TEXT,
            date TEXT,
            time TEXT,
            patient TEXT,
            status TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE visit_notes (
            id TEXT PRIMARY KEY,
            note TEXT,
            timestamp TEXT,
            synced INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // ── Mood entries ──
  Future<void> insertMoodEntry(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('mood_entries', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getMoodEntries(String patientId) async {
    final db = await database;
    return db.query('mood_entries',
        where: 'patient_id = ?', whereArgs: [patientId]);
  }

  // ── Reminders ──
  Future<void> insertReminder(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('reminders', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateReminderConfirmed(String id, bool confirmed) async {
    final db = await database;
    await db.update('reminders', {'confirmed': confirmed ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final db = await database;
    return db.query('reminders');
  }

  // ── Appointments ──
  Future<void> insertAppointment(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('appointments', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAppointments() async {
    final db = await database;
    return db.query('appointments');
  }

  // ── Visit notes ──
  Future<void> insertVisitNote(Map<String, dynamic> row) async {
    final db = await database;
    await db.insert('visit_notes', row,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getVisitNotes() async {
    final db = await database;
    return db.query('visit_notes', orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getUnsyncedMoodEntries() async {
    final db = await database;
    return db.query('mood_entries', where: 'synced = 0');
  }

  Future<void> markMoodEntrySynced(String id) async {
    final db = await database;
    await db.update('mood_entries', {'synced': 1},
        where: 'id = ?', whereArgs: [id]);
  }
}