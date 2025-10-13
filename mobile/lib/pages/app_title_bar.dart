// lib/pages/app_title_bar.dart
import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

const kOrgName = 'Iron Strong Health Initiative'; // change to add “Inc.” if you want

class AppTitleBar extends StatelessWidget {
  final double logoSize;
  const AppTitleBar({super.key, this.logoSize = 40}); // bigger by default

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Use your mark-only asset so it reads well at small sizes
        Image.asset(
          'assets/icon_foreground.png', // or assets/logo.png if you prefer
          height: logoSize,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            kOrgName,
            overflow: TextOverflow.ellipsis,
            // slightly smaller than before
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                ),
          ),
        ),
      ],
    );
  }
}

