import 'dart:async';
import 'package:flutter/material.dart';
import '../models/consumer.dart';
import '../models/employee.dart';
import '../models/inspection.dart';
import '../services/database_helper.dart';
import '../utils/app_theme.dart';
import '../widgets/consumer_card.dart';
import 'change_password_screen.dart';
import 'consumer_detail_screen.dart';
import 'csv_import_screen.dart';
import 'inspection_form_screen.dart';
import 'inspection_list_screen.dart';
import 'ocr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final Employee? employee;
  final Future<void> Function()? onLogout;

  const HomeScreen({super.key, this.employee, this.onLogout});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  int _totalConsumers = 0;
  int _totalInspections = 0;
  bool _isLoadingStats = true;

  List<Consumer> _searchResults = [];
  bool _isSearching = false;
  String _activeQuery = '';

  List<Inspection> _recentInspections = [];

  @override
  void initState() {
    super.initState();
    _refreshDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    setState(() => _isLoadingStats = true);
    final stats = await DatabaseHelper.instance.getStatistics();
    final recents = await DatabaseHelper.instance.getInspections(limit: 5);

    if (mounted) {
      setState(() {
        _totalConsumers = stats['totalConsumers'] as int;
        _totalInspections = stats['totalInspections'] as int;
        _recentInspections = recents;
        _isLoadingStats = false;
      });
    }

    if (_activeQuery.isNotEmpty) {
      _executeSearch(_activeQuery);
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      _executeSearch(query);
    });
  }

  Future<void> _executeSearch(String query) async {
    final trimmed = query.trim();
    setState(() {
      _activeQuery = trimmed;
      _isSearching = true;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    final results = await DatabaseHelper.instance.searchConsumers(trimmed, limit: 30);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SBPDCL App Bar Banner
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF091E3A), Color(0xFF0F3A60), Color(0xFF134074)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                          ),
                          child: Image.asset(
                            'SBDPCL LOGO.jpg',
                            width: 24,
                            height: 24,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SBPDCL',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              'South Bihar Power Distribution Co. Ltd.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Meter OCR & Offline Consumer Lookup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh Dashboard',
                onPressed: _refreshDashboard,
              ),
              if (widget.employee != null && widget.onLogout != null)
                PopupMenuButton<String>(
                  tooltip: 'Employee account',
                  onSelected: (action) async {
                    if (action == 'change_password') {
                      final changed = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ChangePasswordScreen(employee: widget.employee!),
                        ),
                      );
                      if (changed == true && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Password updated successfully.')),
                        );
                      }
                    } else {
                      await widget.onLogout!();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'change_password',
                      child: Row(
                        children: [
                          Icon(Icons.lock_reset_outlined),
                          SizedBox(width: 12),
                          Text('Change password'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 12),
                          Text('Sign out'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // Dashboard Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Metric Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          Icons.storage_rounded,
                          _isLoadingStats ? '...' : '$_totalConsumers',
                          'Master Records',
                          AppTheme.primaryBlue,
                        ),
                        Container(width: 1, height: 32, color: AppTheme.borderSubtle),
                        _buildStatColumn(
                          Icons.assignment_turned_in_rounded,
                          _isLoadingStats ? '...' : '$_totalInspections',
                          'Inspections Logged',
                          AppTheme.statusActive,
                        ),
                        Container(width: 1, height: 32, color: AppTheme.borderSubtle),
                        _buildStatColumn(
                          Icons.wifi_off_rounded,
                          'Offline',
                          'SQLite Mode',
                          Colors.blueGrey,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // OCR Scan Action Banner (Primary Call to Action)
                  InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OcrScannerScreen()),
                      );
                      _refreshDashboard();
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F3A60), Color(0xFF0077B6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 32),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Scan Meter Serial No.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Instant on-device OCR camera scanner & local database match',
                                  style: TextStyle(color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: Colors.white70, size: 28),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CsvImportScreen()),
                            );
                            _refreshDashboard();
                          },
                          icon: const Icon(Icons.upload_file_rounded, size: 18),
                          label: const Text('Import CSV'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InspectionListScreen()),
                            );
                            _refreshDashboard();
                          },
                          icon: const Icon(Icons.history_rounded, size: 18),
                          label: const Text('Inspection Logs'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  const Text(
                    'Instant Consumer Lookup',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by Meter No, CA No, Name, Feeder...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryBlue),
                      suffixIcon: _activeQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Search Results or Recents
          if (_isSearching)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_activeQuery.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  'Found ${_searchResults.length} matching consumer(s)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ),
            ),
            if (_searchResults.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'No records match "$_activeQuery"',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                        ),
                        if (_totalConsumers == 0) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CsvImportScreen()),
                            ),
                            icon: const Icon(Icons.download),
                            label: const Text('Import Master CSV First'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final consumer = _searchResults[index];
                    return ConsumerCard(
                      consumer: consumer,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConsumerDetailScreen(consumer: consumer),
                          ),
                        );
                      },
                      onInspect: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InspectionFormScreen(consumer: consumer),
                          ),
                        );
                      },
                    );
                  },
                  childCount: _searchResults.length,
                ),
              ),
          ] else ...[
            // Default View when no query: Recent Inspections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Inspection Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    if (_recentInspections.isNotEmpty)
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const InspectionListScreen()),
                        ),
                        child: const Text('View All'),
                      ),
                  ],
                ),
              ),
            ),
            if (_recentInspections.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        _totalConsumers == 0
                            ? 'Database empty. Tap "Import CSV" to load SBPDCL master consumer dataset.'
                            : 'No field inspections recorded yet. Tap "Scan Meter" to start.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade600),
                      ),
                      if (_totalConsumers == 0) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CsvImportScreen()),
                          ),
                          icon: const Icon(Icons.file_download_outlined),
                          label: const Text('Load 150 Sample Records'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final insp = _recentInspections[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: insp.hasTampering
                              ? AppTheme.statusDanger.withValues(alpha: 0.15)
                              : AppTheme.statusActive.withValues(alpha: 0.15),
                          child: Icon(
                            insp.hasTampering ? Icons.warning_rounded : Icons.check_circle_outline,
                            color: insp.hasTampering ? AppTheme.statusDanger : AppTheme.statusActive,
                          ),
                        ),
                        title: Text(
                          insp.meterNo ?? 'Unknown Meter',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${insp.meterStatus ?? 'Normal'} • ${insp.meterCondition ?? 'OK'}',
                          style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade700),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const InspectionListScreen()),
                          );
                        },
                      ),
                    );
                  },
                  childCount: _recentInspections.length,
                ),
              ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String count, String label, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.statusNeutral,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
