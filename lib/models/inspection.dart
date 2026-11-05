import 'dart:convert';

class Inspection {
  final int? id;
  final String? meterNo;
  final int? consumerId;
  final String? meterStatus;
  final String? meterCondition;
  final String? otherFindings;
  final double? kwh;
  final double? kvah;
  final double? kw;
  final double? kva;
  final List<String> photoPaths;
  final double? latitude;
  final double? longitude;
  final String? remarks;
  final String timestamp;
  final String? employeeId;

  Inspection({
    this.id,
    this.meterNo,
    this.consumerId,
    this.meterStatus,
    this.meterCondition,
    this.otherFindings,
    this.kwh,
    this.kvah,
    this.kw,
    this.kva,
    List<String>? photoPaths,
    this.latitude,
    this.longitude,
    this.remarks,
    String? timestamp,
    this.employeeId,
  })  : photoPaths = photoPaths ?? [],
        timestamp = timestamp ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'meter_no': meterNo,
      'consumer_id': consumerId,
      'meter_status': meterStatus,
      'meter_condition': meterCondition,
      'other_findings': otherFindings,
      'kwh': kwh,
      'kvah': kvah,
      'kw': kw,
      'kva': kva,
      'photo_paths': jsonEncode(photoPaths),
      'latitude': latitude,
      'longitude': longitude,
      'remarks': remarks,
      'timestamp': timestamp,
      'employee_id': employeeId,
    };
  }

  factory Inspection.fromMap(Map<String, dynamic> map) {
    List<String> photos = [];
    final rawPhotos = map['photo_paths'];
    if (rawPhotos != null && rawPhotos is String && rawPhotos.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawPhotos);
        if (decoded is List) {
          photos = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // Fallback if comma separated
        photos = rawPhotos.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
    }

    return Inspection(
      id: map['id'] as int?,
      meterNo: map['meter_no'] as String?,
      consumerId: map['consumer_id'] as int?,
      meterStatus: map['meter_status'] as String?,
      meterCondition: map['meter_condition'] as String?,
      otherFindings: map['other_findings'] as String?,
      kwh: (map['kwh'] is num) ? (map['kwh'] as num).toDouble() : null,
      kvah: (map['kvah'] is num) ? (map['kvah'] as num).toDouble() : null,
      kw: (map['kw'] is num) ? (map['kw'] as num).toDouble() : null,
      kva: (map['kva'] is num) ? (map['kva'] as num).toDouble() : null,
      photoPaths: photos,
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : null,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : null,
      remarks: map['remarks'] as String?,
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      employeeId: map['employee_id'] as String?,
    );
  }

  bool get hasTampering {
    final cond = (meterCondition ?? '').toLowerCase();
    final findings = (otherFindings ?? '').toLowerCase();
    return cond.contains('tamper') ||
        cond.contains('seal') ||
        cond.contains('bypass') ||
        cond.contains('magnet') ||
        findings.contains('tamper') ||
        findings.contains('theft');
  }
}

