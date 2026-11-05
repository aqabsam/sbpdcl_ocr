import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/consumer.dart';
import '../models/inspection.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_badge.dart';
import 'inspection_form_screen.dart';

class ConsumerDetailScreen extends StatefulWidget {
  final Consumer consumer;

  const ConsumerDetailScreen({super.key, required this.consumer});

  @override
  State<ConsumerDetailScreen> createState() => _ConsumerDetailScreenState();
}

class _ConsumerDetailScreenState extends State<ConsumerDetailScreen> {
  List<Inspection> _inspections = [];
  bool _isLoadingInspections = true;

  @override
  void initState() {
    super.initState();
    _loadInspectionHistory();
  }

  Future<void> _loadInspectionHistory() async {
    setState(() => _isLoadingInspections = true);
    final history = await DatabaseHelper.instance.getInspections(meterNo: widget.consumer.meterNo);
    if (mounted) {
      setState(() {
        _inspections = history;
        _isLoadingInspections = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.consumer;
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final hasDues = c.totalOutstanding > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh History',
            onPressed: _loadInspectionHistory,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(20),
            color: AppTheme.primaryBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        c.consumerName ?? 'Unknown Consumer',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatBadge.status(c.connectionStatus),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.speed_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Meter: ${c.meterNo}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CA: ${c.caNumber ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Button: Start Inspection
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InspectionFormScreen(consumer: c),
                  ),
                );
                if (result == true) {
                  _loadInspectionHistory();
                }
              },
              icon: const Icon(Icons.assignment_add, size: 20),
              label: const Text('RECORD METER INSPECTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentCyan,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),

          // Billing Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: hasDues ? AppTheme.statusDanger : AppTheme.statusActive,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Billing & Payment Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildDetailRow(
                    'Total Outstanding Dues',
                    currencyFormat.format(c.totalOutstanding),
                    isHighlighted: true,
                    highlightColor: hasDues ? AppTheme.statusDanger : AppTheme.statusActive,
                  ),
                  _buildDetailRow('Current Bill', currencyFormat.format(c.currentBill)),
                  _buildDetailRow('Last Payment Date', c.lastPaymentDate ?? 'N/A'),
                  _buildDetailRow(
                    'Last Payment Amount',
                    c.lastPaymentAmount > 0 ? currencyFormat.format(c.lastPaymentAmount) : 'N/A',
                  ),
                ],
              ),
            ),
          ),

          // Meter Specifications Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Meter Specifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Meter Serial No', c.meterNo),
                  _buildDetailRow('Meter Make', c.make ?? 'N/A'),
                  _buildDetailRow('Meter Type', c.meterType ?? 'N/A'),
                  _buildDetailRow('Supply Phase', c.phase ?? '1-Phase'),
                  _buildDetailRow('Tariff Category', c.tariffCategory ?? 'N/A'),
                  _buildDetailRow('Installation Date', c.installationDate ?? 'N/A'),
                  _buildDetailRow('Account Number', c.accountNumber ?? 'N/A'),
                ],
              ),
            ),
          ),

          // Network & Geographic Hierarchy Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_tree_rounded, color: AppTheme.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Network & Grid Hierarchy',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Address', c.address ?? 'N/A'),
                  _buildDetailRow('Village / Town', c.village ?? 'N/A'),
                  _buildDetailRow('Section / Sub-Division', c.section ?? 'N/A'),
                  _buildDetailRow('11kV Feeder', c.feeder ?? 'N/A'),
                  _buildDetailRow('Distribution Transformer (DTR)', c.dtr ?? 'N/A'),
                  _buildDetailRow('Pole Number', c.poleNo ?? 'N/A'),
                ],
              ),
            ),
          ),

          // Past Inspections Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history_rounded, color: AppTheme.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Inspection Logs (${_inspections.length})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (_isLoadingInspections)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_inspections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.assignment_turned_in_outlined,
                                size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'No inspections recorded for this meter yet.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _inspections.length,
                      separatorBuilder: (_, _) => const Divider(height: 16),
                      itemBuilder: (context, index) {
                        final insp = _inspections[index];
                        final dt = DateTime.tryParse(insp.timestamp);
                        final dateStr = dt != null
                            ? DateFormat('dd MMM yyyy, hh:mm a').format(dt)
                            : insp.timestamp;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                StatBadge.condition(insp.meterCondition),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (insp.kwh != null)
                                  Text(
                                    'Reading: ${insp.kwh} kWh',
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                if (insp.kw != null) ...[
                                  const SizedBox(width: 10),
                                  Text('• MD: ${insp.kw} kW', style: const TextStyle(fontSize: 13)),
                                ],
                              ],
                            ),
                            if (insp.remarks != null && insp.remarks!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Remarks: ${insp.remarks}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isHighlighted = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                color: isHighlighted ? (highlightColor ?? AppTheme.primaryDark) : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
