import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/consumer.dart';
import '../models/employee.dart';
import '../models/inspection.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sbpdcl_meter_db.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createDB(db, version);
        await _createEmployeesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createEmployeesTable(db);
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE inspections ADD COLUMN employee_id TEXT');
        }
      },
    );
  }

  Future<void> _createEmployeesTable(Database db) async {
    await db.execute('''
      CREATE TABLE employees (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employee_id TEXT NOT NULL COLLATE NOCASE UNIQUE,
        full_name TEXT NOT NULL,
        designation TEXT NOT NULL,
        department TEXT NOT NULL,
        division TEXT NOT NULL,
        subdivision TEXT NOT NULL,
        mobile TEXT NOT NULL,
        email TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Consumers Table
    await db.execute('''
      CREATE TABLE consumers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meter_no TEXT NOT NULL,
        ca_number TEXT,
        account_number TEXT,
        consumer_name TEXT,
        tariff_category TEXT,
        connection_status TEXT,
        make TEXT,
        phase TEXT,
        meter_type TEXT,
        installation_date TEXT,
        address TEXT,
        village TEXT,
        section TEXT,
        feeder TEXT,
        dtr TEXT,
        pole_no TEXT,
        total_outstanding REAL,
        current_bill REAL,
        last_payment_date TEXT,
        last_payment_amount REAL
      )
    ''');

    // Crucial index for instant OCR lookup
    await db.execute('CREATE INDEX idx_meter_no ON consumers (meter_no)');
    await db.execute('CREATE INDEX idx_ca_number ON consumers (ca_number)');

    // 2. Inspections Table
    await db.execute('''
      CREATE TABLE inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meter_no TEXT,
        consumer_id INTEGER,
        meter_status TEXT,
        meter_condition TEXT,
        other_findings TEXT,
        kwh REAL,
        kvah REAL,
        kw REAL,
        kva REAL,
        photo_paths TEXT,
        latitude REAL,
        longitude REAL,
        remarks TEXT,
        timestamp TEXT,
        employee_id TEXT
      )
    ''');

    await db.execute('CREATE INDEX idx_inspection_meter ON inspections (meter_no)');
  }

  // --- High-Performance Batch Consumer Operations ---

  Future<int> insertConsumerBatch(List<Consumer> consumers, {bool clearExisting = false}) async {
    final db = await database;
    int insertedCount = 0;

    await db.transaction((txn) async {
      if (clearExisting) {
        await txn.delete('consumers');
      }

      final batch = txn.batch();
      for (final consumer in consumers) {
        batch.insert(
          'consumers',
          consumer.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      final results = await batch.commit(noResult: false);
      insertedCount = results.length;
    });

    return insertedCount;
  }

  Future<int> insertConsumer(Consumer consumer) async {
    final db = await database;
    return await db.insert(
      'consumers',
      consumer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Employee?> getEmployeeByEmployeeId(String employeeId) async {
    final db = await database;
    final results = await db.query(
      'employees',
      where: 'employee_id = ?',
      whereArgs: [employeeId.trim()],
      limit: 1,
    );
    return results.isEmpty ? null : Employee.fromMap(results.first);
  }

  Future<Employee?> getEmployeeById(int id) async {
    final db = await database;
    final results = await db.query(
      'employees',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return results.isEmpty ? null : Employee.fromMap(results.first);
  }

  Future<int> insertEmployee(Employee employee) async {
    final db = await database;
    return db.insert(
      'employees',
      employee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> updateEmployeePassword(int id, String passwordHash) async {
    final db = await database;
    return db.update(
      'employees',
      {'password_hash': passwordHash},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateEmployee(Employee employee) async {
    final db = await database;
    return db.update(
      'employees',
      {
        'full_name': employee.fullName,
        'designation': employee.designation,
        'department': employee.department,
        'division': employee.division,
        'subdivision': employee.subdivision,
        'mobile': employee.mobile,
        'email': employee.email,
      },
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  // --- Consumer Queries ---

  Future<Consumer?> getConsumerByMeterNo(String meterNo) async {
    final db = await database;
    final trimmed = meterNo.trim();
    if (trimmed.isEmpty) return null;

    // Exact match first (case insensitive via UPPER)
    final results = await db.query(
      'consumers',
      where: 'UPPER(meter_no) = ?',
      whereArgs: [trimmed.toUpperCase()],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return Consumer.fromMap(results.first);
    }

    // Try without spaces or dashes if exact match not found
    final normalized = trimmed.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final fallbackResults = await db.query(
      'consumers',
      where: "REPLACE(REPLACE(UPPER(meter_no), '-', ''), ' ', '') = ?",
      whereArgs: [normalized],
      limit: 1,
    );

    if (fallbackResults.isNotEmpty) {
      return Consumer.fromMap(fallbackResults.first);
    }

    return null;
  }

  Future<List<Consumer>> searchConsumers(String query, {int limit = 50}) async {
    final db = await database;
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      final results = await db.query('consumers', limit: limit);
      return results.map((row) => Consumer.fromMap(row)).toList();
    }

    final wildcard = '%$trimmed%';
    final results = await db.query(
      'consumers',
      where: '''
        meter_no LIKE ? OR 
        ca_number LIKE ? OR 
        account_number LIKE ? OR 
        consumer_name LIKE ? OR
        address LIKE ?
      ''',
      whereArgs: [wildcard, wildcard, wildcard, wildcard, wildcard],
      limit: limit,
      orderBy: 'consumer_name ASC',
    );

    return results.map((row) => Consumer.fromMap(row)).toList();
  }

  Future<int> getConsumersCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM consumers');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<String>> getConsumerMeterNumbers() async {
    final db = await database;
    final results = await db.query('consumers', columns: ['meter_no']);
    return results
        .map((row) => row['meter_no'] as String? ?? '')
        .where((meterNo) => meterNo.isNotEmpty)
        .toList();
  }

  // --- Inspection Operations ---

  Future<int> insertInspection(Inspection inspection) async {
    final db = await database;
    return await db.insert(
      'inspections',
      inspection.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Inspection>> getInspections({String? meterNo, int limit = 100}) async {
    final db = await database;
    final List<Map<String, dynamic>> results;

    if (meterNo != null && meterNo.trim().isNotEmpty) {
      results = await db.query(
        'inspections',
        where: 'UPPER(meter_no) = ?',
        whereArgs: [meterNo.trim().toUpperCase()],
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    } else {
      results = await db.query(
        'inspections',
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    }

    return results.map((row) => Inspection.fromMap(row)).toList();
  }

  Future<Inspection?> getInspectionById(int id) async {
    final db = await database;
    final results = await db.query(
      'inspections',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return Inspection.fromMap(results.first);
    }
    return null;
  }

  Future<int> deleteInspection(int id) async {
    final db = await database;
    return await db.delete('inspections', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Inspection>> getInspectionsByEmployeeId(String employeeId, {int limit = 100}) async {
    final db = await database;
    final results = await db.query(
      'inspections',
      where: 'employee_id = ?',
      whereArgs: [employeeId.trim()],
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return results.map((row) => Inspection.fromMap(row)).toList();
  }

  Future<int> getInspectionCountByEmployeeId(String employeeId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM inspections WHERE employee_id = ?',
      [employeeId.trim()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Statistics & Diagnostics ---

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final consumerCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM consumers');
    final totalConsumers = Sqflite.firstIntValue(consumerCountRes) ?? 0;

    final inspectionCountRes = await db.rawQuery('SELECT COUNT(*) as count FROM inspections');
    final totalInspections = Sqflite.firstIntValue(inspectionCountRes) ?? 0;

    final duesRes = await db.rawQuery('SELECT SUM(total_outstanding) as sum_dues, COUNT(CASE WHEN total_outstanding > 0 THEN 1 END) as defaulters FROM consumers');
    double totalOutstanding = 0.0;
    int defaulters = 0;
    if (duesRes.isNotEmpty) {
      totalOutstanding = (duesRes.first['sum_dues'] as num?)?.toDouble() ?? 0.0;
      defaulters = (duesRes.first['defaulters'] as int?) ?? 0;
    }

    return {
      'totalConsumers': totalConsumers,
      'totalInspections': totalInspections,
      'totalOutstanding': totalOutstanding,
      'defaulters': defaulters,
    };
  }

  Future<int> clearConsumers() async {
    final db = await database;
    return await db.delete('consumers');
  }

  Future<int> clearInspections() async {
    final db = await database;
    return await db.delete('inspections');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
