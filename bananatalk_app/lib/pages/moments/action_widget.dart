import 'package:flutter/material.dart';

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
              SizedBox(width: 8),
              Text(count.toString()),
            ],
          ),
          SizedBox(height: 8),
          SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }
}
