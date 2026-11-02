import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class VbLogo extends StatelessWidget {
  const VbLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.airport_shuttle_rounded, color: Colors.white, size: 34),
        ),
        const SizedBox(height: 12),
        Text(
          'vanbora',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30, height: 1),
        ),
      ],
    );
  }
}
