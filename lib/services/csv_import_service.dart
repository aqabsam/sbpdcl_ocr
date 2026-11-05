import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/consumer.dart';
import '../models/import_progress.dart';
import 'database_helper.dart';

class CsvImportService {
  static const int _batchChunkSize = 500;
  static const int _maxErrorDetails = 50;

  /// Import consumers from an asset path (e.g. 'assets/sample_sbpdcl_meters.csv').
  static Future<ImportProgress> importFromAsset({
    String assetPath = 'assets/sample_sbpdcl_meters.csv',
    bool clearExisting = true,
    Function(ImportProgress)? onProgress,
  }) async {
    final csvString = await rootBundle.loadString(assetPath);
    return importFromString(
      csvString,
      clearExisting: clearExisting,
      onProgress: onProgress,
    );
  }

  /// Detect the format from the file extension and import CSV, XLSX, or XLS.
  static Future<ImportProgress> importFromFile(
    File file, {
    bool clearExisting = true,
    Function(ImportProgress)? onProgress,
  }) async {
    final extension = file.path.split('.').last.toLowerCase();
    try {
      if (extension == 'csv') {
        return importFromString(
          utf8.decode(await file.readAsBytes()),
          clearExisting: clearExisting,
          onProgress: onProgress,
        );
      }

      if (extension == 'xlsx' || extension == 'xls') {
        onProgress?.call(
          ImportProgress(
            totalRows: 0,
            processedRows: 0,
            insertedRows: 0,
            skippedRows: 0,
            currentAction: 'Reading Excel workbook...',
          ),
        );
        return _importRows(
          _excelRows(await file.readAsBytes()),
          fileType: 'Excel',
          clearExisting: clearExisting,
          onProgress: onProgress,
        );
      }

      return _failed('Unsupported file type. Select a CSV, XLSX, or XLS file.');
    } catch (e) {
      return _failed('Unable to read ${extension.toUpperCase()} file: $e');
    }
  }

  /// Import consumers from CSV text.
  static Future<ImportProgress> importFromString(
    String csvString, {
    bool clearExisting = true,
    Function(ImportProgress)? onProgress,
  }) async {
    try {
      onProgress?.call(
        ImportProgress(
          totalRows: 0,
          processedRows: 0,
          insertedRows: 0,
          skippedRows: 0,
          currentAction: 'Parsing CSV data...',
        ),
      );

      final normalizedCsv = csvString
          .replaceFirst('\uFEFF', '')
          .replaceAll('\r\n', '\n')
          .replaceAll('\r', '\n');
      final rows = const CsvToListConverter(
        eol: '\n',
        shouldParseNumbers: false,
      ).convert(normalizedCsv);

      return _importRows(
        rows,
        fileType: 'CSV',
        clearExisting: clearExisting,
        onProgress: onProgress,
      );
    } catch (e) {
      return _failed('Unable to read CSV file: $e');
    }
  }

  static List<List<dynamic>> _excelRows(List<int> bytes) {
    final workbook = Excel.decodeBytes(bytes);
    List<List<dynamic>>? firstNonEmptySheet;

    for (final sheetName in workbook.tables.keys) {
      final rows = workbook[sheetName].rows
          .map(
            (row) => row.map((cell) => _excelCellValue(cell?.value)).toList(),
          )
          .toList();
      if (rows.isEmpty) continue;

      firstNonEmptySheet ??= rows;
      for (var i = 0; i < rows.length && i < 20; i++) {
        if (_buildHeaderMap(
          rows[i].map((cell) => cell?.toString() ?? '').toList(),
        ).containsKey('meter_no')) {
          return rows.sublist(i);
        }
      }
    }

    return firstNonEmptySheet ?? const [];
  }

  static dynamic _excelCellValue(dynamic value) {
    if (value == null) return null;
    if (value is TextCellValue) return value.value.text;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value;
    if (value is BoolCellValue) return value.value;
    if (value is DateCellValue) {
      return value.asDateTimeLocal().toIso8601String().split('T').first;
    }
    if (value is FormulaCellValue) return value.formula;
    return value.toString();
  }

  static Future<ImportProgress> _importRows(
    List<List<dynamic>> rows, {
    required String fileType,
    required bool clearExisting,
    Function(ImportProgress)? onProgress,
  }) async {
    if (rows.isEmpty) {
      return _failed('$fileType file is empty.');
    }

    final headerRow = rows.first
        .map((cell) => cell?.toString().trim() ?? '')
        .toList();
    final columnMap = _buildHeaderMap(headerRow);
    if (!columnMap.containsKey('meter_no')) {
      return _failed(
        'Mandatory column "meter_no" was not found in $fileType headers.',
      );
    }

    final dataRows = rows.skip(1).toList();
    final totalDataRows = dataRows.length;
    if (clearExisting) {
      onProgress?.call(
        ImportProgress(
          totalRows: totalDataRows,
          processedRows: 0,
          insertedRows: 0,
          skippedRows: 0,
          currentAction: 'Resetting existing consumer table...',
        ),
      );
      await DatabaseHelper.instance.clearConsumers();
    }

    final existingMeterNumbers = clearExisting
        ? <String>{}
        : (await DatabaseHelper.instance.getConsumerMeterNumbers())
              .map(_normalizeMeterNo)
              .toSet();
    final errors = <String>[];
    var errorCount = 0;
    var insertedTotal = 0;
    var skippedTotal = 0;
    var currentChunk = <Consumer>[];

    for (var i = 0; i < totalDataRows; i++) {
      final row = dataRows[i];
      if (row.isEmpty ||
          row.every((cell) => cell == null || cell.toString().trim().isEmpty)) {
        skippedTotal++;
      } else {
        final rowError = _validateRow(row, columnMap);
        final consumer = rowError == null
            ? _rowToConsumer(row, columnMap)
            : null;
        if (rowError != null) {
          skippedTotal++;
          errorCount++;
          if (errors.length < _maxErrorDetails) {
            errors.add('Row ${i + 2}: $rowError');
          }
        } else if (consumer == null) {
          skippedTotal++;
          errorCount++;
          if (errors.length < _maxErrorDetails) {
            errors.add('Row ${i + 2}: a valid meter number is required.');
          }
        } else if (!existingMeterNumbers.add(
          _normalizeMeterNo(consumer.meterNo),
        )) {
          skippedTotal++;
        } else {
          currentChunk.add(consumer);
        }
      }

      if (currentChunk.length >= _batchChunkSize || i == totalDataRows - 1) {
        if (currentChunk.isNotEmpty) {
          insertedTotal += await DatabaseHelper.instance.insertConsumerBatch(
            currentChunk,
            clearExisting: false,
          );
          currentChunk = [];
        }
      }

      if ((i + 1) % _batchChunkSize == 0 || i == totalDataRows - 1) {
        onProgress?.call(
          ImportProgress(
            totalRows: totalDataRows,
            processedRows: i + 1,
            insertedRows: insertedTotal,
            skippedRows: skippedTotal,
            currentAction: 'Importing records: ${i + 1} of $totalDataRows...',
            errors: List.unmodifiable(errors),
            errorCount: errorCount,
          ),
        );
      }
    }

    final finalProgress = ImportProgress(
      totalRows: totalDataRows,
      processedRows: totalDataRows,
      insertedRows: insertedTotal,
      skippedRows: skippedTotal,
      isCompleted: true,
      currentAction: 'Import finished successfully!',
      errors: List.unmodifiable(errors),
      errorCount: errorCount,
    );
    onProgress?.call(finalProgress);
    return finalProgress;
  }

  static ImportProgress _failed(String message) => ImportProgress(
    totalRows: 0,
    processedRows: 0,
    insertedRows: 0,
    skippedRows: 0,
    isCompleted: true,
    errorMessage: message,
  );

  static String _normalizeMeterNo(String meterNo) =>
      meterNo.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  static String? _validateRow(List<dynamic> row, Map<String, int> columnMap) {
    final meterIndex = columnMap['meter_no'];
    if (meterIndex == null || meterIndex >= row.length) {
      return 'a valid meter number is required.';
    }
    final meterNo = row[meterIndex]?.toString().trim() ?? '';
    if (meterNo.isEmpty || _normalizeMeterNo(meterNo).isEmpty) {
      return 'a valid meter number is required.';
    }

    for (final key in [
      'total_outstanding',
      'current_bill',
      'last_payment_amount',
    ]) {
      final index = columnMap[key];
      if (index == null || index >= row.length) continue;
      final value = row[index];
      if (value == null || value.toString().trim().isEmpty) continue;
      if (value is num && value.isFinite) continue;
      final normalized = value.toString().replaceAll(RegExp(r'[^0-9.-]'), '');
      if (double.tryParse(normalized)?.isFinite != true) {
        return '"$key" must contain a valid number.';
      }
    }
    return null;
  }

  static Map<String, int> _buildHeaderMap(List<String> headers) {
    final Map<String, int> map = {};

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (h.contains('meterno') ||
          h == 'meter' ||
          h.contains('serialno') ||
          h == 'srno' ||
          h == 'slno') {
        map['meter_no'] = i;
      } else if (h.contains('canumber') ||
          h == 'cano' ||
          h.contains('consumerno')) {
        map['ca_number'] = i;
      } else if (h.contains('account') || h == 'acctno' || h == 'kno') {
        map['account_number'] = i;
      } else if (h.contains('name') || h.contains('consumer')) {
        map['consumer_name'] = i;
      } else if (h.contains('tariff') || h.contains('category')) {
        map['tariff_category'] = i;
      } else if (h.contains('status')) {
        map['connection_status'] = i;
      } else if (h.contains('make')) {
        map['make'] = i;
      } else if (h.contains('phase')) {
        map['phase'] = i;
      } else if (h.contains('type')) {
        map['meter_type'] = i;
      } else if (h.contains('install') || h.contains('instdate')) {
        map['installation_date'] = i;
      } else if (h.contains('address') || h.contains('location')) {
        map['address'] = i;
      } else if (h.contains('village') ||
          h.contains('town') ||
          h.contains('city')) {
        map['village'] = i;
      } else if (h.contains('section') || h.contains('subdiv')) {
        map['section'] = i;
      } else if (h.contains('feeder')) {
        map['feeder'] = i;
      } else if (h.contains('dtr') || h.contains('transformer')) {
        map['dtr'] = i;
      } else if (h.contains('pole')) {
        map['pole_no'] = i;
      } else if (h.contains('outstanding') ||
          h.contains('arrear') ||
          h.contains('due')) {
        map['total_outstanding'] = i;
      } else if (h.contains('currentbill') ||
          h.contains('billamt') ||
          h.contains('bill')) {
        map['current_bill'] = i;
      } else if (h.contains('lastpaydate') ||
          h.contains('paydate') ||
          h.contains('lastpaymentdate')) {
        map['last_payment_date'] = i;
      } else if (h.contains('lastpayamt') ||
          h.contains('payamount') ||
          h.contains('lastpaymentamount')) {
        map['last_payment_amount'] = i;
      }
    }

    return map;
  }

  static Consumer? _rowToConsumer(
    List<dynamic> row,
    Map<String, int> columnMap,
  ) {
    String? getColumn(String key) {
      final index = columnMap[key];
      if (index == null || index >= row.length) return null;
      final value = row[index]?.toString().trim();
      return (value != null && value.isNotEmpty) ? value : null;
    }

    double getDouble(String key) {
      final value = getColumn(key);
      if (value == null) return 0.0;
      final normalized = value.replaceAll(RegExp(r'[^0-9.-]'), '');
      return double.parse(normalized);
    }

    final meterNo = getColumn('meter_no');
    if (meterNo == null || meterNo.isEmpty) return null;

    return Consumer(
      meterNo: meterNo,
      caNumber: getColumn('ca_number'),
      accountNumber: getColumn('account_number'),
      consumerName: getColumn('consumer_name'),
      tariffCategory: getColumn('tariff_category'),
      connectionStatus: getColumn('connection_status') ?? 'ACTIVE',
      make: getColumn('make'),
      phase: getColumn('phase') ?? '1-Phase',
      meterType: getColumn('meter_type'),
      installationDate: getColumn('installation_date'),
      address: getColumn('address'),
      village: getColumn('village'),
      section: getColumn('section'),
      feeder: getColumn('feeder'),
      dtr: getColumn('dtr'),
      poleNo: getColumn('pole_no'),
      totalOutstanding: getDouble('total_outstanding'),
      currentBill: getDouble('current_bill'),
      lastPaymentDate: getColumn('last_payment_date'),
      lastPaymentAmount: getDouble('last_payment_amount'),
    );
  }
}
