import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/employee.dart';
import '../utils/app_theme.dart';

/// Navigation item identifiers for tracking the active screen.
enum DrawerItem {
  dashboard,
  scanMeter,
  consumerSearch,
  importCsv,
  inspectionHistory,
  recentActivities,
  myProfile,
  editProfile,
  changePassword,
  myInspections,
  about,
  helpSupport,
  privacy,
  appVersion,
}

/// Professional enterprise-grade side navigation drawer for SBPDCL.
class SbpdclDrawer extends StatelessWidget {
  final Employee employee;
  final DrawerItem activeItem;
  final void Function(DrawerItem item) onItemSelected;
  final VoidCallback onLogout;

  const SbpdclDrawer({
    super.key,
    required this.employee,
    required this.activeItem,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          // Employee Header
          _buildHeader(context),

          // Scrollable navigation body
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ─── Main Navigation ───
                _buildSectionTitle('MAIN NAVIGATION'),
                _buildNavItem(
                  context,
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  item: DrawerItem.dashboard,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.document_scanner_rounded,
                  label: 'Scan Meter (OCR)',
                  item: DrawerItem.scanMeter,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.person_search_rounded,
                  label: 'Consumer Search',
                  item: DrawerItem.consumerSearch,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.upload_file_rounded,
                  label: 'Import Consumer CSV',
                  item: DrawerItem.importCsv,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.history_rounded,
                  label: 'Inspection History',
                  item: DrawerItem.inspectionHistory,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.access_time_rounded,
                  label: 'Recent Activities',
                  item: DrawerItem.recentActivities,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // ─── Employee Section ───
                _buildSectionTitle('EMPLOYEE'),
                _buildNavItem(
                  context,
                  icon: Icons.account_circle_rounded,
                  label: 'My Profile',
                  item: DrawerItem.myProfile,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.edit_rounded,
                  label: 'Edit Profile',
                  item: DrawerItem.editProfile,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.lock_reset_rounded,
                  label: 'Change Password',
                  item: DrawerItem.changePassword,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.assignment_ind_rounded,
                  label: 'My Inspection Records',
                  item: DrawerItem.myInspections,
                ),

                const Divider(height: 1, indent: 16, endIndent: 16),

                // ─── Application Information ───
                _buildSectionTitle('APPLICATION'),
                _buildNavItem(
                  context,
                  icon: Icons.info_outline_rounded,
                  label: 'About SBPDCL Meter OCR',
                  item: DrawerItem.about,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  item: DrawerItem.helpSupport,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.shield_outlined,
                  label: 'Privacy & Data Security',
                  item: DrawerItem.privacy,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.verified_rounded,
                  label: 'Application Version',
                  item: DrawerItem.appVersion,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'v1.0.0',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // ─── Logout Button ───
          const Divider(height: 1),
          _buildLogoutTile(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final initials = _getInitials(employee.fullName);
    final createdDate = DateTime.tryParse(employee.createdAt);
    final memberSince = createdDate != null
        ? DateFormat('MMM yyyy').format(createdDate)
        : '';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF091E3A), Color(0xFF0F3A60), Color(0xFF134074)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo and branding row
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: Colors.white,
                      padding: const EdgeInsets.all(3),
                      child: Image.asset(
                        'SBDPCL LOGO.jpg',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SBPDCL',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Meter OCR Application',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Employee avatar and info
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF00E5FF).withValues(alpha: 0.2),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: AppTheme.accentCyan,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.employeeId,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          employee.designation,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Online/Offline indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Offline Mode (SQLite)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  if (memberSince.isNotEmpty)
                    Text(
                      'Since $memberSince',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.blueGrey.shade400,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DrawerItem item,
    Widget? trailing,
  }) {
    final isActive = activeItem == item;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      decoration: BoxDecoration(
        color: isActive
            ? AppTheme.primaryBlue.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -2),
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? AppTheme.primaryBlue : AppTheme.statusNeutral,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primaryBlue : const Color(0xFF334155),
          ),
        ),
        trailing: trailing,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        selectedTileColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
        selected: isActive,
        onTap: () {
          Navigator.pop(context); // Close drawer
          onItemSelected(item);
        },
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
      child: ListTile(
        dense: true,
        leading: const Icon(
          Icons.logout_rounded,
          size: 20,
          color: AppTheme.statusDanger,
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.statusDanger,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: () {
          Navigator.pop(context); // Close drawer first
          _showLogoutConfirmation(context);
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: AppTheme.statusDanger,
          size: 40,
        ),
        title: const Text('Sign Out?'),
        content: const Text(
          'Are you sure you want to sign out of your employee account? '
          'All your inspection records and data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusDanger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
