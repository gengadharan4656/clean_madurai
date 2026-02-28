import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// GradientCard — reusable card with gradient background
class GradientCard extends StatelessWidget {
  final Widget child;
  final Color? primaryColor;
  final Color? secondaryColor;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;
  final double? elevation;

  const GradientCard({
    super.key,
    required this.child,
    this.primaryColor,
    this.secondaryColor,
    this.padding,
    this.borderRadius,
    this.border,
    this.onTap,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final primary = primaryColor ?? AppTheme.primary;
    final secondary = secondaryColor ?? AppTheme.primaryDark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(0.15),
              secondary.withOpacity(0.05),
            ],
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(20),
          border: border ?? Border.all(color: primary.withOpacity(0.2)),
          boxShadow: elevation != null
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.1),
                    blurRadius: elevation! * 4,
                    offset: Offset(0, elevation! * 2),
                  )
                ]
              : null,
        ),
        child: child,
      ),
    );
  }
}

/// InfoCard — a card with icon, title, subtitle
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final Widget? trailing;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

/// StatCard — compact metric display
class StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  final String? change;

  const StatCard({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
    this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    change!,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
