import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/image_utils.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';

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
    final normalizedUrl = profilePicture != null && profilePicture!.isNotEmpty
        ? ImageUtils.normalizeImageUrl(profilePicture)
        : null;

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      child: normalizedUrl != null && normalizedUrl.isNotEmpty
          ? ClipOval(
              child: CachedImageWidget(
                imageUrl: normalizedUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorWidget: _buildFallbackAvatar(),
                placeholder: _buildLoadingAvatar(),
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
