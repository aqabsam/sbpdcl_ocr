import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/import_progress.dart';
import '../services/csv_import_service.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';

class CsvImportScreen extends StatefulWidget {
  const CsvImportScreen({super.key});

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  bool _isImporting = false;
  ImportProgress? _currentProgress;
  bool _clearExisting = true;

  int _totalConsumers = 0;
  double _totalDues = 0.0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final stats = await DatabaseHelper.instance.getStatistics();
    if (mounted) {
      setState(() {
        _totalConsumers = stats['totalConsumers'] as int;
        _totalDues = stats['totalOutstanding'] as double;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _importFromAsset() async {
    setState(() {
      _isImporting = true;
      _currentProgress = null;
    });

    final result = await CsvImportService.importFromAsset(
      assetPath: 'assets/sample_sbpdcl_meters.csv',
      clearExisting: _clearExisting,
      onProgress: (progress) {
        if (mounted) {
          setState(() => _currentProgress = progress);
        }
      },
    );

    await _loadStats();

    if (mounted) {
      setState(() {
        _isImporting = false;
        _currentProgress = result;
      });
      _showResultSnackBar(result);
    }
  }

  Future<void> _pickAndImportFile() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
      );

      if (files.isEmpty) return;

      setState(() {
        _isImporting = true;
        _currentProgress = null;
      });

      var completedRows = 0;
      var insertedRows = 0;
      var skippedRows = 0;
      var errorCount = 0;
      var hasImportedFile = false;
      final errors = <String>[];
      final fileErrors = <String>[];
      var totalRows = 0;

      for (final pickedFile in files) {
        final path = pickedFile.path;
        if (path == null) {
          fileErrors.add('${pickedFile.name}: file path is unavailable.');
          errorCount++;
          continue;
        }

        final result = await CsvImportService.importFromFile(
          File(path),
          clearExisting: _clearExisting && !hasImportedFile,
          onProgress: (progress) {
            if (mounted) {
              setState(() {
                _currentProgress = ImportProgress(
                  totalRows: completedRows + progress.totalRows,
                  processedRows: completedRows + progress.processedRows,
                  insertedRows: insertedRows + progress.insertedRows,
                  skippedRows: skippedRows + progress.skippedRows,
                  currentAction:
                      '${pickedFile.name}: ${progress.currentAction ?? 'Processing...'}',
                  errors: [
                    ...fileErrors,
                    ...errors,
                    ...progress.errors.map(
                      (error) => '${pickedFile.name}: $error',
                    ),
                  ],
                  errorCount: errorCount + progress.errorCount,
                );
              });
            }
          },
        );

        if (result.errorMessage != null) {
          fileErrors.add('${pickedFile.name}: ${result.errorMessage}');
          errorCount++;
        } else {
          hasImportedFile = true;
        }
        totalRows += result.totalRows;
        completedRows += result.processedRows;
        insertedRows += result.insertedRows;
        skippedRows += result.skippedRows;
        errorCount += result.errorCount;
        errors.addAll(
          result.errors.map((error) => '${pickedFile.name}: $error'),
        );
      }

      final importResult = ImportProgress(
        totalRows: totalRows,
        processedRows: completedRows,
        insertedRows: insertedRows,
        skippedRows: skippedRows,
        isCompleted: true,
        currentAction: 'Import finished.',
        errorMessage: insertedRows == 0 && fileErrors.isNotEmpty
            ? fileErrors.join('\n')
            : null,
        errors: [...fileErrors, ...errors],
        errorCount: errorCount,
      );

      await _loadStats();
      if (mounted) {
        setState(() {
          _isImporting = false;
          _currentProgress = importResult;
        });
        _showResultSnackBar(importResult);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File selection failed: $e'),
            backgroundColor: AppTheme.statusDanger,
          ),
        );
      }
    }
  }

  void _showResultSnackBar(ImportProgress res) {
    if (res.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.errorMessage!),
          backgroundColor: AppTheme.statusDanger,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${res.insertedRows}; skipped ${res.skippedRows}; errors ${res.errorCount}.',
          ),
          backgroundColor: res.errorCount > 0 || res.skippedRows > 0
              ? AppTheme.statusWarning
              : AppTheme.statusActive,
        ),
      );
    }
  }

  Future<void> _confirmClearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Consumer Master Data?'),
        content: const Text(
          'This will delete all consumer records from the local SQLite database. Inspection logs will remain untouched.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusDanger,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.clearConsumers();
      await _loadStats();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consumer database cleared.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Master Consumer Data'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear Consumer Data',
            onPressed: _isImporting ? null : _confirmClearDatabase,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Database Summary Card
          Card(
            margin: EdgeInsets.zero,
            color: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOCAL SQLITE DATABASE STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingStats)
                    const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_totalConsumers',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Consumers Indexed',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyFormat.format(_totalDues),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFED7AA),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Total Dues in DB',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Import Settings
          Card(
            margin: EdgeInsets.zero,
            child: SwitchListTile(
              value: _clearExisting,
              title: const Text(
                'Replace Existing Consumer Records',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Wipes previous consumer rows before importing new records.',
                style: TextStyle(fontSize: 12),
              ),
              activeThumbColor: AppTheme.primaryBlue,
              onChanged: _isImporting
                  ? null
                  : (val) => setState(() => _clearExisting = val),
            ),
          ),
          const SizedBox(height: 16),

          // Options Header
          const Text(
            'Select Import Source',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 10),

          // Option 1: Sample SBPDCL Data
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accentCyan.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.dataset_rounded,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sample SBPDCL Dataset',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              '150 realistic consumer & billing records pre-packaged in app bundle.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importFromAsset,
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('LOAD BUNDLED SBPDCL DATA'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Option 2: Pick a CSV or Excel file
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.file_upload_rounded,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom CSV or Excel File',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Pick .csv, .xlsx, or .xls files exported from SBPDCL/DISCOM billing server. You can select multiple files.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isImporting ? null : _pickAndImportFile,
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text('SELECT CSV / EXCEL FILES FROM DEVICE'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Progress Card
          if (_isImporting || _currentProgress != null) ...[
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isImporting
                              ? 'Import in Progress'
                              : 'Import Complete',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _isImporting
                                ? AppTheme.primaryBlue
                                : AppTheme.statusActive,
                          ),
                        ),
                        if (_isImporting)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: _currentProgress?.percentage,
                      backgroundColor: Colors.grey.shade200,
                      color: AppTheme.accentCyan,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _currentProgress?.currentAction ?? 'Processing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blueGrey.shade700,
                          ),
                        ),
                        Text(
                          '${((_currentProgress?.percentage ?? 0) * 100).toInt()}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    if (_currentProgress != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Imported: ${_currentProgress!.insertedRows} | Skipped: ${_currentProgress!.skippedRows} | Errors: ${_currentProgress!.errorCount} | Total: ${_currentProgress!.totalRows}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_currentProgress!.errors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: Text(
                            'Import errors (${_currentProgress!.errorCount})',
                            style: const TextStyle(
                              color: AppTheme.statusDanger,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          children: _currentProgress!.errors
                              .map(
                                (error) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      error,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        if (_currentProgress!.errorCount >
                            _currentProgress!.errors.length)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Showing the first ${_currentProgress!.errors.length} errors.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
