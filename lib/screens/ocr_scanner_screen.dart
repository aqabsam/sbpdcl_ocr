import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/consumer.dart';
import '../services/database_helper.dart';
import '../services/ocr_service.dart';
import '../utils/app_theme.dart';
import '../widgets/scanner_overlay.dart';
import '../widgets/stat_badge.dart';
import 'consumer_detail_screen.dart';
import 'inspection_form_screen.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  String? _cameraErrorMessage;

  final OcrService _ocrService = OcrService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isProcessingOcr = false;
  List<String> _detectedCandidates = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _cameraErrorMessage = 'No camera found on this device.';
        });
        return;
      }

      // Default to back camera
      _selectedCameraIndex = _cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );
      if (_selectedCameraIndex == -1) _selectedCameraIndex = 0;

      await _setupController(_cameras[_selectedCameraIndex]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraErrorMessage = 'Camera access error: $e';
        });
      }
    }
  }

  Future<void> _setupController(CameraDescription camera) async {
    _cameraController?.dispose();
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          _cameraErrorMessage = null;
          _isFlashOn = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _cameraErrorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    try {
      final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newMode);
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (_) {}
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _setupController(_cameras[_selectedCameraIndex]);
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized || _isProcessingOcr) return;

    setState(() => _isProcessingOcr = true);

    try {
      final XFile photo = await _cameraController!.takePicture();
      await _processImage(File(photo.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingOcr = false);
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (picked != null) {
        setState(() => _isProcessingOcr = true);
        await _processImage(File(picked.path));
        setState(() => _isProcessingOcr = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingOcr = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting photo: $e')),
        );
      }
    }
  }

  Future<void> _processImage(File file) async {
    final result = await _ocrService.processImageFile(file);

    if (!mounted) return;

    setState(() {
      _detectedCandidates = result.candidates;
    });

    if (result.hasMatch) {
      _showConsumerMatchSheet(result.matchedConsumer!);
    } else if (result.candidates.isNotEmpty) {
      _showCandidatesSheet(result.candidates);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No meter serial number recognized. Please position camera closer.'),
          backgroundColor: AppTheme.statusWarning,
        ),
      );
    }
  }

  Future<void> _lookupMeterManually(String meterNo) async {
    setState(() => _isProcessingOcr = true);
    final consumer = await DatabaseHelper.instance.getConsumerByMeterNo(meterNo);
    setState(() => _isProcessingOcr = false);

    if (!mounted) return;

    if (consumer != null) {
      _showConsumerMatchSheet(consumer);
    } else {
      _showUnmatchedDialog(meterNo);
    }
  }

  void _promptManualEntry() {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Meter Number'),
        content: TextField(
          controller: textCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'e.g. SB100234',
            prefixIcon: Icon(Icons.speed_rounded),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                _lookupMeterManually(val);
              }
            },
            child: const Text('Lookup'),
          ),
        ],
      ),
    );
  }

  void _showConsumerMatchSheet(Consumer consumer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.statusActive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: AppTheme.statusActive, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'INSTANT DB MATCH FOUND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.statusActive,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Meter: ${consumer.meterNo}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                StatBadge.status(consumer.connectionStatus),
              ],
            ),
            const Divider(height: 24),
            Text(
              consumer.consumerName ?? 'Unknown',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'CA No: ${consumer.caNumber ?? 'N/A'} • Tariff: ${consumer.tariffCategory ?? 'N/A'} • Phase: ${consumer.phase ?? '1-Phase'}',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'Address: ${consumer.address ?? 'N/A'}, ${consumer.village ?? ''}',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: consumer.totalOutstanding > 0
                    ? AppTheme.statusDanger.withValues(alpha: 0.08)
                    : AppTheme.statusActive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    consumer.totalOutstanding > 0 ? 'Total Dues Overdue:' : 'Bill Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: consumer.totalOutstanding > 0 ? AppTheme.statusDanger : AppTheme.statusActive,
                    ),
                  ),
                  Text(
                    consumer.totalOutstanding > 0
                        ? '₹${consumer.totalOutstanding.toStringAsFixed(2)}'
                        : 'No Dues',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: consumer.totalOutstanding > 0 ? AppTheme.statusDanger : AppTheme.statusActive,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ConsumerDetailScreen(consumer: consumer),
                        ),
                      );
                    },
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InspectionFormScreen(consumer: consumer),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assignment_add, size: 18),
                    label: const Text('Inspect Meter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCandidatesSheet(List<String> candidates) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Recognized Serial Candidates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Select candidate below to query SQLite database or record an inspection:',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: candidates.map((cand) {
                return ActionChip(
                  avatar: const Icon(Icons.speed, size: 16, color: AppTheme.primaryBlue),
                  label: Text(
                    cand,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _lookupMeterManually(cand);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showUnmatchedDialog(String meterNo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Consumer Found'),
        content: Text(
          'Meter "$meterNo" is not currently indexed in the local database.\n\nYou can still perform an inspection log entry for this meter.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InspectionFormScreen(initialMeterNo: meterNo),
                ),
              );
            },
            icon: const Icon(Icons.assignment_add),
            label: const Text('Record Inspection Anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final scanWindow = Rect.fromCenter(
      center: Offset(screenSize.width / 2, screenSize.height * 0.42),
      width: screenSize.width * 0.82,
      height: 160,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Electric Meter OCR Scanner'),
        backgroundColor: Colors.black.withValues(alpha: 0.7),
        actions: [
          if (_isCameraInitialized) ...[
            IconButton(
              icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
              tooltip: 'Torch Flashlight',
              onPressed: _toggleFlash,
            ),
            if (_cameras.length > 1)
              IconButton(
                icon: const Icon(Icons.flip_camera_ios),
                tooltip: 'Switch Camera',
                onPressed: _switchCamera,
              ),
          ],
          IconButton(
            icon: const Icon(Icons.keyboard_outlined),
            tooltip: 'Type Serial Number',
            onPressed: _promptManualEntry,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camera View or Fallback
          if (_isCameraInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            _buildCameraFallbackView(),

          // 2. Targeting HUD & Scanning Laser Overlay
          if (_isCameraInitialized)
            ScannerOverlay(scanWindow: scanWindow),

          // 3. Instruction Banner at top
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.crop_free, color: Color(0xFF00E5FF), size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Align meter serial number inside the cyan frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Detected Candidates Quick Bar
          if (_detectedCandidates.isNotEmpty)
            Positioned(
              bottom: 120,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Detected Serials:',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _detectedCandidates.map((cand) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(cand, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              backgroundColor: AppTheme.accentCyan.withValues(alpha: 0.2),
                              labelStyle: const TextStyle(color: Colors.white),
                              onPressed: () => _lookupMeterManually(cand),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Bottom Action Controls
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Pick photo from gallery
                FloatingActionButton.small(
                  heroTag: 'fab_gallery',
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  onPressed: _pickImageFromGallery,
                  tooltip: 'Pick from Gallery',
                  child: const Icon(Icons.photo_library),
                ),

                // Primary Capture & OCR Button
                GestureDetector(
                  onTap: _isProcessingOcr ? null : _captureAndScan,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: const Color(0xFF00E5FF),
                    ),
                    child: Center(
                      child: _isProcessingOcr
                          ? const CircularProgressIndicator(color: Colors.black, strokeWidth: 3)
                          : const Icon(Icons.camera_alt, color: Colors.black, size: 36),
                    ),
                  ),
                ),

                // Manual Input Button
                FloatingActionButton.small(
                  heroTag: 'fab_manual',
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                  onPressed: _promptManualEntry,
                  tooltip: 'Manual Entry',
                  child: const Icon(Icons.edit),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraFallbackView() {
    return Container(
      color: const Color(0xFF091E3A),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: AppTheme.accentCyan),
              const SizedBox(height: 16),
              const Text(
                'Camera Hardware Standby',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _cameraErrorMessage ?? 'Initializing camera device or running in simulated environment.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Option 1: Pick Image File for OCR
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick Meter Photo from Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Test with SBPDCL Demo Serials
              const Text(
                '— OR QUICK-TEST DEMO SERIALS —',
                style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  'SB100234',
                  'SB100235',
                  'GP882910',
                  'SEC77410',
                  'LT948201',
                  'HPL55102',
                ].map((s) {
                  return ActionChip(
                    label: Text(s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    backgroundColor: Colors.white12,
                    onPressed: () => _lookupMeterManually(s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: _promptManualEntry,
                icon: const Icon(Icons.keyboard, color: Colors.white70),
                label: const Text('Type Any Meter Serial Manually', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
