import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? profilePicture;
  final String userName;
  final double radius;

  const UserAvatar({
    Key? key,
    this.profilePicture,
    required this.userName,
    required this.radius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: profilePicture != null && profilePicture!.isNotEmpty
          ? ClipOval(
              child: Image.network(
                profilePicture!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildFallbackAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildLoadingAvatar();
                },
              ),
            )
          : _buildFallbackAvatar(),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Colors.grey[300],
      child: Center(
        child: Text(
          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.7,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      color: Colors.grey[200],
      child: Center(
        child: SizedBox(
          width: radius,
          height: radius,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
