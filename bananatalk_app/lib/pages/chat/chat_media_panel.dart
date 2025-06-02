import 'package:flutter/material.dart';
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
          height: 220 * animationController.value,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey[200]!,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
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
                      color: Colors.grey[800],
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
                        icon: Icons.insert_drive_file,
                        label: 'Document',
                        color: Colors.blue,
                        onTap: () => onMediaOption('document'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      MediaOptionButton(
                        icon: Icons.location_on,
                        label: 'Location',
                        color: Colors.green,
                        onTap: () => onMediaOption('location'),
                      ),
                      MediaOptionButton(
                        icon: Icons.contact_page,
                        label: 'Contact',
                        color: Colors.orange,
                        onTap: () => onMediaOption('contact'),
                      ),
                      MediaOptionButton(
                        icon: Icons.mic,
                        label: 'Voice',
                        color: Colors.red,
                        onTap: () => onMediaOption('audio'),
                      ),
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
