import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/consumer.dart';
import '../utils/meter_number_cleaner.dart';
import 'database_helper.dart';

class OcrScanResult {
  final String fullText;
  final List<String> candidates;
  final Consumer? matchedConsumer;
  final String? matchedMeterNo;

  OcrScanResult({
    required this.fullText,
    required this.candidates,
    this.matchedConsumer,
    this.matchedMeterNo,
  });

  bool get hasMatch => matchedConsumer != null;
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Process an image file from camera capture or gallery
  Future<OcrScanResult> processImageFile(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    return processInputImage(inputImage);
  }

  /// Process an InputImage (from file or streaming buffer)
  Future<OcrScanResult> processInputImage(InputImage inputImage) async {
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    final String fullText = recognizedText.text;

    // 1. Extract candidates using utility heuristic
    final List<String> candidates = MeterNumberCleaner.extractCandidates(fullText);

    // 2. Instant query against SQLite database for match
    Consumer? matchedConsumer;
    String? matchedMeterNo;

    for (final candidate in candidates) {
      final consumer = await DatabaseHelper.instance.getConsumerByMeterNo(candidate);
      if (consumer != null) {
        matchedConsumer = consumer;
        matchedMeterNo = consumer.meterNo;
        break;
      }
    }

    return OcrScanResult(
      fullText: fullText,
      candidates: candidates,
      matchedConsumer: matchedConsumer,
      matchedMeterNo: matchedMeterNo,
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}

