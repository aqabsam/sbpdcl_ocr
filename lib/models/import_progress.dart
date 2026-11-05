class ImportProgress {
  final int totalRows;
  final int processedRows;
  final int insertedRows;
  final int skippedRows;
  final bool isCompleted;
  final String? currentAction;
  final String? errorMessage;
  final List<String> errors;
  final int errorCount;

  ImportProgress({
    required this.totalRows,
    required this.processedRows,
    required this.insertedRows,
    required this.skippedRows,
    this.isCompleted = false,
    this.currentAction,
    this.errorMessage,
    this.errors = const [],
    int? errorCount,
  }) : errorCount = errorCount ?? errors.length;

  double get percentage =>
      totalRows > 0 ? (processedRows / totalRows).clamp(0.0, 1.0) : 0.0;
}
