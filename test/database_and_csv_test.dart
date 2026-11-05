import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sbpdcl_ocr_app/models/consumer.dart';
import 'package:sbpdcl_ocr_app/models/inspection.dart';
import 'package:sbpdcl_ocr_app/services/database_helper.dart';
import 'package:sbpdcl_ocr_app/services/csv_import_service.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearConsumers();
    await DatabaseHelper.instance.clearInspections();
  });

  group('DatabaseHelper & CsvImportService Tests', () {
    test('insert and query consumer by meter_no with index', () async {
      final consumer = Consumer(
        meterNo: 'SB100234',
        caNumber: '1001020301',
        accountNumber: 'ACCT98201',
        consumerName: 'Rajesh Kumar Sharma',
        tariffCategory: 'DS-II',
        connectionStatus: 'ACTIVE',
        make: 'Genus',
        phase: '1-Phase',
        totalOutstanding: 1250.50,
        currentBill: 450.00,
        lastPaymentDate: '2024-01-10',
        lastPaymentAmount: 1200.00,
      );

      await DatabaseHelper.instance.insertConsumer(consumer);

      // Query exact
      final queried = await DatabaseHelper.instance.getConsumerByMeterNo(
        'SB100234',
      );
      expect(queried, isNotNull);
      expect(queried!.consumerName, 'Rajesh Kumar Sharma');
      expect(queried.caNumber, '1001020301');
      expect(queried.totalOutstanding, 1250.50);
      expect(queried.isDefaulter, isTrue);

      // Query case-insensitive and with dash
      final queriedNormalized = await DatabaseHelper.instance
          .getConsumerByMeterNo('sb-100234');
      expect(queriedNormalized, isNotNull);
      expect(queriedNormalized!.meterNo, 'SB100234');
    });

    test('CSV parsing and batch import into SQLite', () async {
      const sampleCsv =
          '''meter_no,ca_number,account_number,consumer_name,tariff_category,connection_status,make,phase,meter_type,installation_date,address,village,section,feeder,dtr,pole_no,total_outstanding,current_bill,last_payment_date,last_payment_amount
SB100234,1001020301,ACCT98201,Rajesh Kumar Sharma,DS-II,ACTIVE,Genus,1-Phase,Electronic Static,2021-03-15,House No 42 Boring Road,Patna,Patna West,Boring Road Feeder,DTR-BOR-04,P-012,1250.50,450.00,2024-01-10,1200.00
GP882910,1001020306,ACCT98206,Vikramaditya Roy,NDS-II,ACTIVE,Genus,1-Phase,Electronic Static,2020-08-22,Station Road Near SBI,Gaya,Gaya Town,Civil Lines Feeder,DTR-GAY-05,P-015,310.00,580.00,2024-02-12,850.00
SEC77410,1001020311,ACCT98211,Dinesh Chandra Jha,DS-II,ACTIVE,Secure,1-Phase,Smart Prepaid,2023-01-15,Ashiana Nagar Phase 1,Patna,Patna West,Ashiana Feeder,DTR-ASH-02,P-063,0.00,285.00,2024-02-22,500.00''';

      final progress = await CsvImportService.importFromString(
        sampleCsv,
        clearExisting: true,
      );

      expect(progress.isCompleted, isTrue);
      expect(progress.insertedRows, 3);
      expect(progress.errorMessage, isNull);

      final count = await DatabaseHelper.instance.getConsumersCount();
      expect(count, 3);

      final dinesh = await DatabaseHelper.instance.getConsumerByMeterNo(
        'SEC77410',
      );
      expect(dinesh, isNotNull);
      expect(dinesh!.consumerName, 'Dinesh Chandra Jha');
      expect(dinesh.totalOutstanding, 0.0);
      expect(dinesh.isDefaulter, isFalse);
    });

    test(
      'CSV import skips existing and repeated meters and reports invalid rows',
      () async {
        await DatabaseHelper.instance.insertConsumer(
          Consumer(meterNo: 'EX-100', consumerName: 'Existing Consumer'),
        );

        const sampleCsv = '''meter_no,consumer_name,total_outstanding
EX100,Existing Consumer,100
NEW200,New Consumer,25.50
NEW-200,Duplicate Consumer,10
BAD300,Invalid Amount,not-a-number
,Missing Meter,0''';

        final progress = await CsvImportService.importFromString(
          sampleCsv,
          clearExisting: false,
        );

        expect(progress.isCompleted, isTrue);
        expect(progress.insertedRows, 1);
        expect(progress.skippedRows, 4);
        expect(progress.errorCount, 2);
        expect(
          progress.errors,
          contains('Row 5: "total_outstanding" must contain a valid number.'),
        );
        expect(
          progress.errors,
          contains('Row 6: a valid meter number is required.'),
        );
        expect(await DatabaseHelper.instance.getConsumersCount(), 2);
      },
    );

    test('insert inspection log and retrieve by meter_no', () async {
      final inspection = Inspection(
        meterNo: 'SB100234',
        consumerId: 1,
        meterStatus: 'Normal / Running',
        meterCondition: 'Seal Broken / Tampered',
        otherFindings: 'Optical port cover missing',
        kwh: 4521.8,
        kvah: 4610.2,
        kw: 3.4,
        kva: 3.8,
        photoPaths: ['/tmp/photo1.jpg', '/tmp/photo2.jpg'],
        latitude: 25.59409,
        longitude: 85.13756,
        remarks: 'Reported to sub-divisional engineer',
      );

      final id = await DatabaseHelper.instance.insertInspection(inspection);
      expect(id, isNonZero);

      final history = await DatabaseHelper.instance.getInspections(
        meterNo: 'SB100234',
      );
      expect(history.length, 1);
      expect(history.first.meterNo, 'SB100234');
      expect(history.first.hasTampering, isTrue);
      expect(history.first.kwh, 4521.8);
      expect(history.first.photoPaths.length, 2);
      expect(history.first.photoPaths.first, '/tmp/photo1.jpg');
    });

    test('search consumers with wildcards', () async {
      const sampleCsv =
          '''meter_no,ca_number,account_number,consumer_name,tariff_category,connection_status,make,phase,meter_type,installation_date,address,village,section,feeder,dtr,pole_no,total_outstanding,current_bill,last_payment_date,last_payment_amount
SB100234,1001020301,ACCT98201,Rajesh Kumar Sharma,DS-II,ACTIVE,Genus,1-Phase,Electronic Static,2021-03-15,House No 42 Boring Road,Patna,Patna West,Boring Road Feeder,DTR-BOR-04,P-012,1250.50,450.00,2024-01-10,1200.00
GP882910,1001020306,ACCT98206,Vikramaditya Roy,NDS-II,ACTIVE,Genus,1-Phase,Electronic Static,2020-08-22,Station Road Near SBI,Gaya,Gaya Town,Civil Lines Feeder,DTR-GAY-05,P-015,310.00,580.00,2024-02-12,850.00''';

      await CsvImportService.importFromString(sampleCsv, clearExisting: true);

      final resultsName = await DatabaseHelper.instance.searchConsumers(
        'Rajesh',
      );
      expect(resultsName.length, 1);
      expect(resultsName.first.meterNo, 'SB100234');

      final resultsCa = await DatabaseHelper.instance.searchConsumers(
        '1001020306',
      );
      expect(resultsCa.length, 1);
      expect(resultsCa.first.consumerName, 'Vikramaditya Roy');
    });
  });
}
