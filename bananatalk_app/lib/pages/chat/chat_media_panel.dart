import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'media_option_button.dart';

class ChatMediaPanel extends StatelessWidget {
  final AnimationController animationController;
  final Function(String) onMediaOption;

  const ChatMediaPanel({
    Key? key,
    required this.animationController,
    required this.onMediaOption,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Container(
          height: 260 * animationController.value,
          decoration: BoxDecoration(
            color: context.surfaceColor,
            border: Border(
              top: BorderSide(
                color: context.dividerColor,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Opacity(
              opacity: animationController.value,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MediaOptionButton(
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        color: Colors.pink,
                        onTap: () => onMediaOption('camera'),
                      ),
                      MediaOptionButton(
                        icon: Icons.photo_library,
                        label: 'Gallery',
                        color: Colors.purple,
                        onTap: () => onMediaOption('gallery'),
                      ),
                      MediaOptionButton(
                        icon: Icons.location_on,
                        label: 'Location',
                        color: Colors.green,
                        onTap: () => onMediaOption('location'),
                      ),
                      MediaOptionButton(
                        icon: Icons.mic,
                        label: 'Voice',
                        color: Colors.red,
                        onTap: () => onMediaOption('audio'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MediaOptionButton(
                        icon: Icons.insert_drive_file,
                        label: 'Document',
                        color: Colors.orange,
                        onTap: () => onMediaOption('document'),
                      ),
                      MediaOptionButton(
                        icon: Icons.videocam,
                        label: 'Video',
                        color: Colors.blue,
                        onTap: () => onMediaOption('video'),
                      ),
                      const SizedBox(width: 60), // spacer
                      const SizedBox(width: 60), // spacer
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
