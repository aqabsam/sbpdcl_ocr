import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class StatBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatBadge.status(String? status) {
    final s = (status ?? 'ACTIVE').toUpperCase();
    if (s.contains('DISCONNECT')) {
      return StatBadge(
        label: 'DISCONNECTED',
        backgroundColor: AppTheme.statusDanger.withValues(alpha: 0.12),
        textColor: AppTheme.statusDanger,
        icon: Icons.power_off_rounded,
      );
    } else if (s.contains('NOTICE') || s.contains('STOP')) {
      return StatBadge(
        label: s,
        backgroundColor: AppTheme.statusWarning.withValues(alpha: 0.12),
        textColor: AppTheme.statusWarning,
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return StatBadge(
        label: 'ACTIVE',
        backgroundColor: AppTheme.statusActive.withValues(alpha: 0.12),
        textColor: AppTheme.statusActive,
        icon: Icons.check_circle_outline_rounded,
      );
    }
  }

  factory StatBadge.tariff(String? tariff) {
    return StatBadge(
      label: tariff ?? 'DS-II',
      backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
      textColor: AppTheme.primaryBlue,
      icon: Icons.electrical_services_rounded,
    );
  }

  factory StatBadge.phase(String? phase) {
    final p = phase ?? '1-Phase';
    final is3Phase = p.contains('3');
    return StatBadge(
      label: p,
      backgroundColor: is3Phase
          ? Colors.deepPurple.withValues(alpha: 0.1)
          : Colors.blueGrey.withValues(alpha: 0.1),
      textColor: is3Phase ? Colors.deepPurple : Colors.blueGrey.shade800,
      icon: Icons.bolt_rounded,
    );
  }

  factory StatBadge.condition(String? condition) {
    final cond = (condition ?? 'OK').toUpperCase();
    if (cond.contains('TAMPER') || cond.contains('BYPASS') || cond.contains('THEFT')) {
      return StatBadge(
        label: cond,
        backgroundColor: AppTheme.statusDanger.withValues(alpha: 0.15),
        textColor: AppTheme.statusDanger,
        icon: Icons.warning_rounded,
      );
    } else {
      return StatBadge(
        label: cond,
        backgroundColor: AppTheme.statusActive.withValues(alpha: 0.12),
        textColor: AppTheme.statusActive,
        icon: Icons.verified_user_rounded,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

