import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/consumer.dart';
import '../models/inspection.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_badge.dart';
import 'consumer_detail_screen.dart';

class InspectionListScreen extends StatefulWidget {
  const InspectionListScreen({super.key});

  @override
  State<InspectionListScreen> createState() => _InspectionListScreenState();
}

class _InspectionListScreenState extends State<InspectionListScreen> {
  List<Inspection> _inspections = [];
  bool _isLoading = true;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _loadInspections();
  }

  Future<void> _loadInspections() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper.instance.getInspections();
    if (mounted) {
      setState(() {
        _inspections = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteInspection(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Inspection?'),
        content: const Text('Are you sure you want to remove this inspection log record?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deleteInspection(id);
      _loadInspections();
    }
  }

  void _showInspectionDetailSheet(Inspection insp) async {
    Consumer? consumer;
    if (insp.meterNo != null && insp.meterNo!.isNotEmpty) {
      consumer = await DatabaseHelper.instance.getConsumerByMeterNo(insp.meterNo!);
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final dt = DateTime.tryParse(insp.timestamp);
        final dateStr = dt != null
            ? DateFormat('dd MMM yyyy, hh:mm a').format(dt)
            : insp.timestamp;

        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ListView(
                controller: controller,
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'METER SERIAL NO.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.statusNeutral,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            insp.meterNo ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      StatBadge.condition(insp.meterCondition),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recorded on $dateStr',
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                  ),
                  const Divider(height: 24),

                  // Consumer reference if found
                  if (consumer != null) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.primaryBlue,
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      title: Text(
                        consumer.consumerName ?? 'Consumer',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text('CA: ${consumer.caNumber ?? 'N/A'} • Tariff: ${consumer.tariffCategory ?? 'N/A'}'),
                      trailing: TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConsumerDetailScreen(consumer: consumer!),
                            ),
                          );
                        },
                        child: const Text('View Profile'),
                      ),
                    ),
                    const Divider(height: 20),
                  ],

                  // Details
                  _buildDetailItem('Meter Status', insp.meterStatus ?? 'N/A'),
                  _buildDetailItem('Meter Condition', insp.meterCondition ?? 'N/A'),
                  if (insp.otherFindings != null && insp.otherFindings!.isNotEmpty)
                    _buildDetailItem('Other Findings', insp.otherFindings!),
                  _buildDetailItem('Active Energy (kWh)', insp.kwh != null ? '${insp.kwh} kWh' : 'Not recorded'),
                  _buildDetailItem('Apparent Energy (kVAh)', insp.kvah != null ? '${insp.kvah} kVAh' : 'Not recorded'),
                  _buildDetailItem('Max Demand (kW)', insp.kw != null ? '${insp.kw} kW' : 'Not recorded'),
                  _buildDetailItem('Demand (kVA)', insp.kva != null ? '${insp.kva} kVA' : 'Not recorded'),

                  // GPS Coordinates
                  _buildDetailItem(
                    'GPS Geotag',
                    insp.latitude != null && insp.longitude != null
                        ? '${insp.latitude!.toStringAsFixed(5)}°, ${insp.longitude!.toStringAsFixed(5)}°'
                        : 'No GPS data',
                  ),

                  // Remarks
                  if (insp.remarks != null && insp.remarks!.isNotEmpty)
                    _buildDetailItem('Remarks', insp.remarks!),

                  // Photos
                  const SizedBox(height: 12),
                  const Text(
                    'Inspection Photos',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (insp.photoPaths.isEmpty)
                    Text(
                      'No photos attached.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    )
                  else
                    SizedBox(
                      height: 110,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: insp.photoPaths.length,
                        itemBuilder: (context, i) {
                          final p = insp.photoPaths[i];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderSubtle),
                              image: DecorationImage(
                                image: FileImage(File(p)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              val,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _inspections.where((insp) {
      if (_searchFilter.isEmpty) return true;
      final query = _searchFilter.toUpperCase();
      return (insp.meterNo ?? '').toUpperCase().contains(query) ||
          (insp.meterCondition ?? '').toUpperCase().contains(query) ||
          (insp.meterStatus ?? '').toUpperCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspection Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInspections,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => setState(() => _searchFilter = val.trim()),
              decoration: InputDecoration(
                hintText: 'Filter by meter serial or condition...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchFilter.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchFilter = ''),
                      )
                    : null,
              ),
            ),
          ),

          // Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recorded Inspections: ${filtered.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
                Text(
                  'Offline SQLite Store',
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.assignment_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              _searchFilter.isEmpty
                                  ? 'No meter inspections recorded yet.'
                                  : 'No inspections match "$_searchFilter"',
                              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final insp = filtered[index];
                          final dt = DateTime.tryParse(insp.timestamp);
                          final dateStr = dt != null
                              ? DateFormat('dd MMM yyyy, hh:mm a').format(dt)
                              : insp.timestamp;

                          return Dismissible(
                            key: Key('insp_${insp.id}_${insp.timestamp}'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              if (insp.id != null) {
                                await _deleteInspection(insp.id!);
                              }
                              return false;
                            },
                            child: Card(
                              child: ListTile(
                                onTap: () => _showInspectionDetailSheet(insp),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: insp.hasTampering
                                      ? AppTheme.statusDanger.withValues(alpha: 0.15)
                                      : AppTheme.primaryBlue.withValues(alpha: 0.1),
                                  child: Icon(
                                    insp.hasTampering ? Icons.warning_rounded : Icons.speed_rounded,
                                    color: insp.hasTampering ? AppTheme.statusDanger : AppTheme.primaryBlue,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      insp.meterNo ?? 'Unknown Meter',
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    StatBadge.condition(insp.meterCondition),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Status: ${insp.meterStatus ?? 'Normal'} • $dateStr',
                                      style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        if (insp.kwh != null)
                                          Text(
                                            '${insp.kwh} kWh',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: AppTheme.primaryDark,
                                            ),
                                          ),
                                        if (insp.latitude != null) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.location_on, size: 12, color: Colors.blueGrey),
                                          Text(
                                            ' GPS Tagged',
                                            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                                          ),
                                        ],
                                        if (insp.photoPaths.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          const Icon(Icons.camera_alt, size: 12, color: Colors.blueGrey),
                                          Text(
                                            ' ${insp.photoPaths.length} photos',
                                            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

