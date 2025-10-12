import 'package:flutter/material.dart';

class AppTitleBar extends StatelessWidget {
  final double logoSize;
  const AppTitleBar({super.key, this.logoSize = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/logo.png', height: logoSize),
        const SizedBox(width: 8),
        const Flexible(
          child: Text(
            'Iron Strong Health Initiative',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
