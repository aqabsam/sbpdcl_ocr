import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/consumer.dart';
import '../utils/app_theme.dart';
import 'stat_badge.dart';

class ConsumerCard extends StatelessWidget {
  final Consumer consumer;
  final VoidCallback? onTap;
  final VoidCallback? onInspect;

  const ConsumerCard({
    super.key,
    required this.consumer,
    this.onTap,
    this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    final hasDues = consumer.totalOutstanding > 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: hasDues ? AppTheme.statusDanger.withValues(alpha: 0.3) : AppTheme.borderSubtle,
          width: hasDues ? 1.2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Meter No & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.speed_rounded,
                          color: AppTheme.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'METER NO.',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.statusNeutral,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            consumer.meterNo,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryBlue,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  StatBadge.status(consumer.connectionStatus),
                ],
              ),
              const SizedBox(height: 12),

              // Consumer Name & CA Number
              Text(
                consumer.consumerName ?? 'Unknown Consumer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'CA: ${consumer.caNumber ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Acct: ${consumer.accountNumber ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Address & Feeder Info
              if (consumer.address != null || consumer.feeder != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.blueGrey.shade400),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        [
                          consumer.address,
                          consumer.village,
                          consumer.section,
                        ].where((e) => e != null && e.isNotEmpty).join(', '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Divider
              const Divider(height: 1, color: AppTheme.borderSubtle),
              const SizedBox(height: 10),

              // Bottom Row: Badges, Outstanding Dues & Inspect Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      StatBadge.tariff(consumer.tariffCategory),
                      StatBadge.phase(consumer.phase),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        hasDues ? 'OUTSTANDING' : 'BILL STATUS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: hasDues ? AppTheme.statusDanger : AppTheme.statusActive,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        hasDues ? currencyFormatter.format(consumer.totalOutstanding) : 'Nil Due',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: hasDues ? AppTheme.statusDanger : AppTheme.statusActive,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (onInspect != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onInspect,
                    icon: const Icon(Icons.assignment_add, size: 18),
                    label: const Text('Record Inspection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

