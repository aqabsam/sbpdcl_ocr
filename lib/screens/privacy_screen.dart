import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Privacy & Data Security information screen.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Data Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            margin: EdgeInsets.zero,
            color: AppTheme.primaryBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Security',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your data is protected with industry-standard security practices.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          _buildSection(
            icon: Icons.storage_rounded,
            title: 'Local Data Storage',
            content:
                'All application data is stored locally on your device using SQLite. '
                'Consumer records, inspection logs, photographs, and employee information '
                'are never transmitted over the internet. The application operates entirely '
                'in offline mode.',
          ),

          _buildSection(
            icon: Icons.lock_rounded,
            title: 'Password Security',
            content:
                'Employee passwords are hashed using PBKDF2-SHA256 with 600,000 iterations '
                'and a cryptographically random 16-byte salt. Plain-text passwords are never '
                'stored. Password verification uses constant-time comparison to prevent '
                'timing attacks.',
          ),

          _buildSection(
            icon: Icons.person_rounded,
            title: 'Employee Data',
            content:
                'Employee registration information (name, ID, designation, department, '
                'contact details) is stored locally for authentication and inspection '
                'record attribution. This data is not shared with external services.',
          ),

          _buildSection(
            icon: Icons.camera_alt_rounded,
            title: 'Photographs & Media',
            content:
                'Inspection photographs are stored locally on your device\'s file system. '
                'Images are not uploaded to any cloud storage or remote server. '
                'Photo quality is optimized for storage efficiency.',
          ),

          _buildSection(
            icon: Icons.location_on_rounded,
            title: 'Location Data',
            content:
                'GPS coordinates are captured during field inspections for geo-tagging '
                'purposes. Location data is stored locally with the inspection record '
                'and is not transmitted to external services.',
          ),

          _buildSection(
            icon: Icons.delete_rounded,
            title: 'Data Retention',
            content:
                'Inspection records, consumer data, and imported CSV records are retained '
                'in the local database until explicitly deleted by the user. Logging out '
                'does not delete any records. Uninstalling the application will remove '
                'all locally stored data.',
          ),

          _buildSection(
            icon: Icons.admin_panel_settings_rounded,
            title: 'Access Control',
            content:
                'Access to the application is controlled through employee authentication. '
                'Each employee must sign in with their unique Employee ID and password. '
                'Session management uses secure local preferences.',
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              '© 2024 SBPDCL. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primaryBlue),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey.shade700,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
