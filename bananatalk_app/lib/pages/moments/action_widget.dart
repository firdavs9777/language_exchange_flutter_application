import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

class ActionButton extends StatelessWidget {
  final IconData icon;

  final VoidCallback onPressed;
  final int count;
  final bool isLiked;

  const ActionButton(
      {Key? key,
      required this.icon,
      required this.onPressed,
      required this.count,
      required this.isLiked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24),
              Spacing.hGapSM,
              Text(count.toString()),
            ],
          ),
          Spacing.gapSM,
          SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }
}
