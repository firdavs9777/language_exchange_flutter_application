import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Pick an optional cover photo while creating a club or a gathering.
///
/// OPTIONAL, and labelled so. The whole point of this control is that ignoring
/// it is a normal way to finish the form — someone organising a coffee meetup
/// on their phone usually has no photo to hand, and demanding one would cost
/// more groups than it gains.
///
/// Holds a local [File] only. The photo is uploaded AFTER the group exists,
/// because the upload endpoint is keyed on the new id — and a failed upload
/// must never fail the creation, since the group is perfectly valid without a
/// picture.
///
/// One widget for both forms so the copy, the size cap and the picker options
/// cannot drift apart.
class GroupCoverPicker extends StatelessWidget {
  const GroupCoverPicker({
    super.key,
    required this.file,
    required this.onChanged,
  });

  final File? file;
  final ValueChanged<File?> onChanged;

  Future<void> _pick(BuildContext context, ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      // Capped here rather than only server-side: a modern phone photo is
      // several megabytes and this uploads on a mobile connection.
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) onChanged(File(picked.path));
  }

  Future<void> _choose(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.groupCoverFromLibrary),
              onTap: () => Navigator.pop(sheetContext, 'library'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.groupCoverTakePhoto),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            if (file != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l10n.groupCoverRemove,
                    style: const TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(sheetContext, 'remove'),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice == 'remove') {
      onChanged(null);
      return;
    }
    await _pick(
      context,
      choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      key: const Key('group-cover-picker'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _choose(context),
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.containerColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.textMuted.withValues(alpha: 0.3)),
          image: file != null
              ? DecorationImage(image: FileImage(file!), fit: BoxFit.cover)
              : null,
        ),
        child: file != null
            ? const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black54,
                    child: Icon(Icons.edit, size: 16, color: Colors.white),
                  ),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: context.textMuted),
                  const SizedBox(height: 6),
                  Text(
                    l10n.groupCoverAddOptional,
                    style: context.captionSmall
                        .copyWith(color: context.textMuted),
                  ),
                ],
              ),
      ),
    );
  }
}
