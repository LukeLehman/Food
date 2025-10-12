// lib/pages/app_title_bar.dart
import 'package:flutter/material.dart';

class AppTitleBar extends StatelessWidget {
  const AppTitleBar({super.key, this.logoSize = 36});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bigger logo
        Image.asset(
          'assets/logo.png',
          height: logoSize,
          width: logoSize,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 10),
        // Slightly smaller, subtle title
        Flexible(
          child: Text(
            'Iron Strong Health Initiative',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,           // smaller wording
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
