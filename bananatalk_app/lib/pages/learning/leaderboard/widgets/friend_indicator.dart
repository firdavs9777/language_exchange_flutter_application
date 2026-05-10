import 'package:flutter/material.dart';

class FriendIndicator extends StatelessWidget {
  final double size;
  const FriendIndicator({super.key, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
