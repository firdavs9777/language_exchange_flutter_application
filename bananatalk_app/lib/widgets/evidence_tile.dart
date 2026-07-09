import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class EvidenceTile extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  const EvidenceTile({
    Key? key,
    required this.file,
    required this.onRemove,
  }) : super(key: key);

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final isImage = file.extension != null &&
        ['jpg', 'jpeg', 'png'].contains(file.extension!.toLowerCase());

    return ListTile(
      leading: Icon(
        isImage ? Icons.image : Icons.description,
        color: Colors.green,
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(_formatFileSize(file.size)),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onRemove,
      ),
    );
  }
}
