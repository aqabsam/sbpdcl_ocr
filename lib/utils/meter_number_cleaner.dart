class MeterNumberCleaner {
  static final RegExp _cleanRegex = RegExp(r'[^A-Za-z0-9]');
  static final RegExp _commonPrefixes = RegExp(
    r'^(meter\s*(no|num|number)?|sl\.?\s*(no|num)?|sr\.?\s*(no|num)?|s/no|s/n|serial\s*(no)?|s\.no)\.?\s*[:.\- ]*',
    caseSensitive: false,
  );

  static final Set<String> _blacklist = {
    'SBPDCL',
    'NBPDCL',
    'BSPHCL',
    'KWH',
    'KVAH',
    'PHASE',
    'STATIC',
    'ENERGY',
    'METER',
    'ELECTRIC',
    'VOLTS',
    'AMPS',
    'INDIA',
    'MADE',
    'PROPERTY',
    'SINGLE',
    'THREE',
    'WIRE',
    'CLASS',
    'TYPE',
    'MODEL',
    'ACCURACY',
    'RATING',
    'CURRENT',
    'VOLTAGE',
    'DATE',
    'YEAR',
    'GENUS',
    'SECURE',
    'SCHNEIDER',
    'L&T',
  };

  /// Clean a raw string by trimming and removing punctuation
  static String normalize(String input) {
    String cleaned = input.trim().toUpperCase();
    cleaned = cleaned.replaceAll(_commonPrefixes, '');
    return cleaned.replaceAll(_cleanRegex, '');
  }

  /// Extracts candidate meter numbers from raw OCR text
  static List<String> extractCandidates(String fullOcrText) {
    final Set<String> candidates = {};

    // 1. Process line by line
    final lines = fullOcrText.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Check if line contains a prefix like "Sr No: SB100234"
      final match = _commonPrefixes.firstMatch(line);
      if (match != null) {
        final remainder = line.substring(match.end).trim();
        final normalized = normalize(remainder);
        if (_isValidCandidate(normalized)) {
          candidates.add(normalized);
        }
      }

      // 2. Tokenize by whitespace
      final tokens = line.split(RegExp(r'\s+'));
      for (final token in tokens) {
        final normalized = normalize(token);
        if (_isValidCandidate(normalized)) {
          candidates.add(normalized);
        }
      }
    }

    // 3. Regex search for typical meter number patterns (e.g. 2-4 letters followed by 5-8 digits, or 6-10 digits)
    final patternRegex = RegExp(r'\b([A-Z]{0,4}\d{5,9}[A-Z]{0,2})\b', caseSensitive: false);
    for (final match in patternRegex.allMatches(fullOcrText)) {
      final val = normalize(match.group(0)!);
      if (_isValidCandidate(val)) {
        candidates.add(val);
      }
    }

    // Sort candidates: favor those with both letters & digits, or lengths between 6 and 12
    final sortedList = candidates.toList()
      ..sort((a, b) {
        final aScore = _scoreCandidate(a);
        final bScore = _scoreCandidate(b);
        return bScore.compareTo(aScore);
      });

    return sortedList;
  }

  static bool _isValidCandidate(String str) {
    if (str.length < 5 || str.length > 16) return false;
    if (_blacklist.contains(str.toUpperCase())) return false;

    // Must contain at least 3 digits
    final digitCount = str.replaceAll(RegExp(r'\D'), '').length;
    if (digitCount < 3) return false;

    return true;
  }

  static int _scoreCandidate(String str) {
    int score = 0;
    // Standard meter serial length is usually 6 - 10 characters
    if (str.length >= 6 && str.length <= 10) score += 5;

    // Contains both letters and digits (common for utility meters: SB100234, GP882910)
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(str);
    final hasDigits = RegExp(r'\d').hasMatch(str);
    if (hasLetters && hasDigits) score += 10;

    // Meter prefix matches common SBPDCL prefixes
    if (str.startsWith('SB') ||
        str.startsWith('GP') ||
        str.startsWith('LT') ||
        str.startsWith('SEC') ||
        str.startsWith('GEN') ||
        str.startsWith('HPL')) {
      score += 15;
    }

    return score;
  }
}
