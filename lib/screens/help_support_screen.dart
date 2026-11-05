import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// Help & Support screen for SBPDCL Meter OCR application.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
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
                      Icons.support_agent_rounded,
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
                          'Need Help?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Find answers to common questions and contact support.',
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

          // FAQ Section
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),

          _buildFaqTile(
            question: 'How do I scan a meter serial number?',
            answer:
                'Tap "Scan Meter (OCR)" from the dashboard or navigation drawer. '
                'Point your camera at the meter\'s serial number plate. '
                'The OCR engine will automatically detect and extract the serial number.',
          ),
          _buildFaqTile(
            question: 'How do I import consumer data?',
            answer:
                'Navigate to "Import Consumer CSV" from the drawer. You can load the '
                'bundled sample dataset or pick a CSV file exported from the SBPDCL/DISCOM billing server.',
          ),
          _buildFaqTile(
            question: 'Does this app require internet?',
            answer:
                'No. This application works entirely offline using a local SQLite database. '
                'All consumer data, inspection records, and OCR processing happen on-device.',
          ),
          _buildFaqTile(
            question: 'How do I record a field inspection?',
            answer:
                'After scanning a meter or searching for a consumer, tap "Record Meter Inspection." '
                'Fill in the meter status, condition, readings, attach photos, and save. '
                'GPS coordinates are captured automatically.',
          ),
          _buildFaqTile(
            question: 'Can I change my Employee ID?',
            answer:
                'No. The Employee ID is a unique identifier assigned during registration and cannot be modified. '
                'Contact your IT administrator if you need a different Employee ID.',
          ),
          _buildFaqTile(
            question: 'Where is my data stored?',
            answer:
                'All data is stored locally in an SQLite database on your device. '
                'No data is transmitted over the network. Photos are stored in the app\'s local storage.',
          ),

          const SizedBox(height: 20),

          // Contact Section
          const Text(
            'Contact IT Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildContactRow(
                    Icons.business_rounded,
                    'IT Department, SBPDCL',
                  ),
                  const Divider(height: 16),
                  _buildContactRow(
                    Icons.location_on_rounded,
                    'Vidyut Bhawan, Bailey Road, Patna - 800001',
                  ),
                  const Divider(height: 16),
                  _buildContactRow(
                    Icons.email_rounded,
                    'it-support@sbpdcl.co.in',
                  ),
                  const Divider(height: 16),
                  _buildContactRow(
                    Icons.phone_rounded,
                    '0612-2504000',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFaqTile({required String question, required String answer}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(
          Icons.help_outline_rounded,
          color: AppTheme.accentCyan,
          size: 20,
        ),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryDark,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
