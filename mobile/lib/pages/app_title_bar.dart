// lib/pages/app_title_bar.dart
import 'package:flutter/material.dart';

class AppTitleBar extends StatelessWidget {
  final double logoSize;
  final double titleFontSize;
  const AppTitleBar({super.key, this.logoSize = 44, this.titleFontSize = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logo.png', height: logoSize),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Iron Strong Health Initiative',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: titleFontSize),
          ),
        ),
      ],
    );
  }
}
