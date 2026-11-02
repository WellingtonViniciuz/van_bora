import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../models/occupancy.dart';

class OccupancySelector extends StatelessWidget {
  const OccupancySelector({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final Occupancy? selected;
  final bool enabled;
  final ValueChanged<Occupancy> onSelected;

  static IconData _iconFor(Occupancy option) => switch (option) {
        Occupancy.vazia => Icons.person_outline_rounded,
        Occupancy.metade => Icons.group_outlined,
        Occupancy.cheia => Icons.groups_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in Occupancy.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _OccupancyOption(
                label: option.label,
                icon: _iconFor(option),
                selected: selected == option,
                enabled: enabled,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelected(option);
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _OccupancyOption extends StatelessWidget {
  const _OccupancyOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: 'Lotação $label',
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.5,
        child: Material(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: enabled ? onTap : null,
            child: SizedBox(
              height: 104,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: selected ? AppColors.primary : AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
