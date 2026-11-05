import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/consumer.dart';
import '../models/inspection.dart';
import '../services/database_helper.dart';
import '../services/location_service.dart';
import '../utils/app_theme.dart';

class InspectionFormScreen extends StatefulWidget {
  final Consumer? consumer;
  final String? initialMeterNo;

  const InspectionFormScreen({
    super.key,
    this.consumer,
    this.initialMeterNo,
  });

  @override
  State<InspectionFormScreen> createState() => _InspectionFormScreenState();
}

class _InspectionFormScreenState extends State<InspectionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _meterNoCtrl;
  final TextEditingController _kwhCtrl = TextEditingController();
  final TextEditingController _kvahCtrl = TextEditingController();
  final TextEditingController _kwCtrl = TextEditingController();
  final TextEditingController _kvaCtrl = TextEditingController();
  final TextEditingController _otherFindingsCtrl = TextEditingController();
  final TextEditingController _remarksCtrl = TextEditingController();

  String _meterStatus = 'Normal / Running';
  final List<String> _statusOptions = [
    'Normal / Running',
    'Defective / Burnt',
    'Display Blank / Dim',
    'Meter Missing / Stolen',
    'Glass Broken',
  ];

  String _meterCondition = 'OK / Intact';
  final List<String> _conditionOptions = [
    'OK / Intact',
    'Seal Broken / Tampered',
    'Magnet Applied',
    'Direct Bypass / Loop Wire',
    'Shunt Connected',
    'Reverse Flow / Terminal Altered',
  ];

  final List<String> _photoPaths = [];
  final ImagePicker _imagePicker = ImagePicker();

  double? _latitude;
  double? _longitude;
  double? _accuracy;
  bool _isFetchingLocation = false;
  String? _locationStatusText;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final initialNo = widget.consumer?.meterNo ?? widget.initialMeterNo ?? '';
    _meterNoCtrl = TextEditingController(text: initialNo);
    _fetchGpsLocation();
  }

  @override
  void dispose() {
    _meterNoCtrl.dispose();
    _kwhCtrl.dispose();
    _kvahCtrl.dispose();
    _kwCtrl.dispose();
    _kvaCtrl.dispose();
    _otherFindingsCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchGpsLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _locationStatusText = 'Acquiring GPS fix...';
    });

    final locResult = await LocationService.getCurrentLocation();

    if (mounted) {
      setState(() {
        _isFetchingLocation = false;
        if (locResult.isSuccess) {
          _latitude = locResult.latitude;
          _longitude = locResult.longitude;
          _accuracy = locResult.accuracy;
          _locationStatusText = locResult.formattedCoordinates;
        } else {
          _locationStatusText = locResult.errorMessage ?? 'GPS unavailable';
        }
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1280,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          _photoPaths.add(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final inspection = Inspection(
        meterNo: _meterNoCtrl.text.trim().toUpperCase(),
        consumerId: widget.consumer?.id,
        meterStatus: _meterStatus,
        meterCondition: _meterCondition,
        otherFindings: _otherFindingsCtrl.text.trim().isEmpty ? null : _otherFindingsCtrl.text.trim(),
        kwh: double.tryParse(_kwhCtrl.text.trim()),
        kvah: double.tryParse(_kvahCtrl.text.trim()),
        kw: double.tryParse(_kwCtrl.text.trim()),
        kva: double.tryParse(_kvaCtrl.text.trim()),
        photoPaths: _photoPaths,
        latitude: _latitude,
        longitude: _longitude,
        remarks: _remarksCtrl.text.trim().isEmpty ? null : _remarksCtrl.text.trim(),
        timestamp: DateTime.now().toIso8601String(),
      );

      await DatabaseHelper.instance.insertInspection(inspection);

      if (mounted) {
        setState(() => _isSaving = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving inspection: $e'),
            backgroundColor: AppTheme.statusDanger,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: AppTheme.statusActive, size: 48),
        title: const Text('Inspection Saved'),
        content: Text(
          'Inspection findings for meter ${_meterNoCtrl.text.trim()} have been recorded successfully to local SQLite storage.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, true); // Pop screen with success
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Meter Inspection'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Consumer Banner if preselected
            if (widget.consumer != null) ...[
              Card(
                margin: EdgeInsets.zero,
                color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppTheme.primaryBlue, width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, color: AppTheme.primaryBlue),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.consumer!.consumerName ?? 'Consumer',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            Text(
                              'CA: ${widget.consumer!.caNumber ?? 'N/A'} • Tariff: ${widget.consumer!.tariffCategory ?? 'DS-II'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Meter Number
            TextFormField(
              controller: _meterNoCtrl,
              decoration: const InputDecoration(
                labelText: 'Meter Serial Number *',
                prefixIcon: Icon(Icons.speed_rounded),
                hintText: 'e.g. SB100234',
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Meter number is required' : null,
            ),
            const SizedBox(height: 16),

            // Meter Working Status
            const Text(
              'Meter Working Status *',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _meterStatus,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.build_circle_outlined),
              ),
              items: _statusOptions
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _meterStatus = v);
              },
            ),
            const SizedBox(height: 16),

            // Meter Condition & Tampering
            const Text(
              'Meter Condition & Tampering Findings *',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _meterCondition,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.shield_outlined,
                  color: _meterCondition.contains('OK') ? AppTheme.statusActive : AppTheme.statusDanger,
                ),
              ),
              items: _conditionOptions
                  .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _meterCondition = v);
              },
            ),
            const SizedBox(height: 16),

            // Other findings
            TextFormField(
              controller: _otherFindingsCtrl,
              decoration: const InputDecoration(
                labelText: 'Other Physical Findings / Seal Numbers',
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'e.g. Terminal cover seal intact, MD reset button working',
              ),
            ),
            const SizedBox(height: 20),

            // Electrical Meter Readings
            const Text(
              'Meter Parameter Readings',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kwhCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Active Energy (kWh)',
                      suffixText: 'kWh',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kvahCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Apparent Energy (kVAh)',
                      suffixText: 'kVAh',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _kwCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Max Demand (kW)',
                      suffixText: 'kW',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _kvaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Demand (kVA)',
                      suffixText: 'kVA',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // GPS Geotagging
            Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.location_on, color: AppTheme.primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'GPS Geo-Tagging',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        if (_isFetchingLocation)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          TextButton.icon(
                            onPressed: _fetchGpsLocation,
                            icon: const Icon(Icons.my_location, size: 16),
                            label: const Text('Refresh GPS', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _locationStatusText ?? 'Acquiring GPS coordinates...',
                      style: TextStyle(
                        fontSize: 13,
                        color: _latitude != null ? Colors.black87 : Colors.grey.shade600,
                        fontWeight: _latitude != null ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (_accuracy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Accuracy: ±${_accuracy!.toStringAsFixed(1)}m',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Inspection Photos
            Card(
              margin: EdgeInsets.zero,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.camera_alt_outlined, color: AppTheme.primaryBlue, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Inspection Photos',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
                              tooltip: 'Take Photo',
                              onPressed: () => _pickPhoto(ImageSource.camera),
                            ),
                            IconButton(
                              icon: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
                              tooltip: 'Pick from Gallery',
                              onPressed: () => _pickPhoto(ImageSource.gallery),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_photoPaths.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        child: Text(
                          'No photos attached. Tap camera or gallery above.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      )
                    else
                      SizedBox(
                        height: 90,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _photoPaths.length,
                          itemBuilder: (context, index) {
                            final path = _photoPaths[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  margin: const EdgeInsets.only(right: 10, top: 4),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.borderSubtle),
                                    image: DecorationImage(
                                      image: FileImage(File(path)),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 0,
                                  right: 6,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _photoPaths.removeAt(index);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Remarks
            TextFormField(
              controller: _remarksCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Inspector Remarks / Notes',
                prefixIcon: Icon(Icons.notes_rounded),
                hintText: 'Enter any additional observations on site...',
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _submitForm,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(_isSaving ? 'SAVING...' : 'SAVE INSPECTION RECORD'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
