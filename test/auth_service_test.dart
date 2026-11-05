import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:sbpdcl_ocr_app/services/auth_service.dart';
import 'package:sbpdcl_ocr_app/services/database_helper.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    AuthService.useTestHashIterations(100000);
    final databasePath = join(await getDatabasesPath(), 'sbpdcl_meter_db.db');
    await databaseFactory.deleteDatabase(databasePath);

    final legacyDatabase = await databaseFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
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
          await db.execute('CREATE INDEX idx_meter_no ON consumers (meter_no)');
          await db.execute(
            'CREATE INDEX idx_ca_number ON consumers (ca_number)',
          );
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
              timestamp TEXT
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_inspection_meter ON inspections (meter_no)',
          );
          await db.insert('consumers', {
            'meter_no': 'PRESERVED-METER',
            'consumer_name': 'Legacy Consumer',
          });
          await db.insert('inspections', {
            'meter_no': 'PRESERVED-METER',
            'timestamp': '2025-01-01T00:00:00.000',
          });
        },
      ),
    );
    await legacyDatabase.close();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final database = await DatabaseHelper.instance.database;
    await database.delete('employees');
  });

  tearDown(() async {
    final database = await DatabaseHelper.instance.database;
    await database.delete('employees');
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
  });

  test(
    'version 1 migration adds employees and preserves existing records',
    () async {
      final database = await DatabaseHelper.instance.database;
      expect(await database.getVersion(), 3);
      expect(await database.query('employees'), isEmpty);
      expect(
        await database.rawQuery('SELECT COUNT(*) AS count FROM consumers'),
        everyElement(containsPair('count', 1)),
      );
      expect(
        await database.rawQuery('SELECT COUNT(*) AS count FROM inspections'),
        everyElement(containsPair('count', 1)),
      );

      await AuthService.instance.initialize();
      expect(await database.query('employees'), isEmpty);
      expect(
        await database.rawQuery('SELECT COUNT(*) AS count FROM consumers'),
        everyElement(containsPair('count', 1)),
      );
      expect(
        await database.rawQuery('SELECT COUNT(*) AS count FROM inspections'),
        everyElement(containsPair('count', 1)),
      );
    },
  );

  test('initialization does not create a shared default account', () async {
    expect(await AuthService.instance.initialize(), isNull);
    expect(
      await DatabaseHelper.instance.getEmployeeByEmployeeId('SBPDCL_ADMIN'),
      isNull,
    );
  });

  test(
    'registration hashes passwords and rejects duplicate IDs case-insensitively',
    () async {
      await AuthService.instance.initialize();
      const password = 'FieldOfficer!2026';
      final employee = await AuthService.instance.registerEmployee(
        fullName: 'Test Field Officer',
        employeeId: 'sbpdcl-field-01',
        designation: 'Field Officer',
        department: 'Operations',
        division: 'Patna',
        subdivision: 'West',
        mobile: '+919876543210',
        email: 'officer@example.in',
        password: password,
      );

      expect(employee.employeeId, 'SBPDCL-FIELD-01');
      expect(employee.passwordHash, isNot(password));
      expect(
        AuthService.instance.registerEmployee(
          fullName: 'Duplicate User',
          employeeId: 'SbPdCl-FiElD-01',
          designation: 'Field Officer',
          department: 'Operations',
          division: 'Patna',
          subdivision: 'West',
          mobile: '9876543210',
          email: 'duplicate@example.in',
          password: password,
        ),
        throwsA(isA<EmployeeIdAlreadyExistsException>()),
      );
      expect(
        (await AuthService.instance.login(
          employeeId: 'SBPDCL-FIELD-01',
          password: password,
          rememberMe: false,
        ))?.fullName,
        'Test Field Officer',
      );
    },
  );

  test(
    'password change uses a new hash and does not overwrite on initialization',
    () async {
      await AuthService.instance.initialize();
      final admin = await AuthService.instance.registerEmployee(
        fullName: 'Test Administrator',
        employeeId: 'SBPDCL-ADMIN-TEST',
        designation: 'IT Administrator',
        department: 'IT Department',
        division: '',
        subdivision: '',
        mobile: '',
        email: '',
        password: 'AdminTest!2026',
      );
      final oldHash = admin.passwordHash;

      expect(
        await AuthService.instance.changePassword(
          employee: admin,
          currentPassword: 'AdminTest!2026',
          newPassword: 'UpdatedAdmin!2026',
        ),
        isTrue,
      );
      await AuthService.instance.initialize();
      final updated = await DatabaseHelper.instance.getEmployeeByEmployeeId(
        'SBPDCL-ADMIN-TEST',
      );
      expect(updated!.passwordHash, isNot(oldHash));

      expect(
        await AuthService.instance.login(
          employeeId: 'SBPDCL-ADMIN-TEST',
          password: 'AdminTest!2026',
          rememberMe: false,
        ),
        isNull,
      );
      expect(
        (await AuthService.instance.login(
          employeeId: 'SBPDCL-ADMIN-TEST',
          password: 'UpdatedAdmin!2026',
          rememberMe: false,
        ))?.employeeId,
        'SBPDCL-ADMIN-TEST',
      );
    },
  );
}
