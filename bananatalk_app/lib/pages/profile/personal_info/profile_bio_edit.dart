import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileBioEdit extends ConsumerStatefulWidget {
  final String currentBio;
  const ProfileBioEdit({Key? key, required this.currentBio}) : super(key: key);

  @override
  ConsumerState<ProfileBioEdit> createState() => _ProfileBioEditState();
}

class _ProfileBioEditState extends ConsumerState<ProfileBioEdit> {
  late TextEditingController _bioController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentBio);
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveBio() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(authServiceProvider).updateUserBio(
            bio: _bioController.text.trim(),
          );

      if (mounted) {
        // Refresh user provider to update UI
        ref.refresh(userProvider);
        Navigator.pop(context, _bioController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bio updated successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: context.surfaceColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Bio',
          style: context.titleLarge,
        ),
        actions: [
          if (_isSaving)
            Padding(
              padding: Spacing.paddingLG,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveBio,
              child: Text(
                'Save',
                style: context.titleMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: Spacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.cardBackground,
                  borderRadius: AppRadius.borderMD,
                  boxShadow: AppShadows.sm,
                ),
                child: TextField(
                  controller: _bioController,
                  maxLines: 8,
                  maxLength: 500,
                  style: context.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Tell others about yourself...',
                    hintStyle: context.bodyMedium.copyWith(
                      color: context.textHint,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.borderMD,
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: context.cardBackground,
                    contentPadding: Spacing.paddingLG,
                  ),
                ),
              ),
              Spacing.gapMD,
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _bioController,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length}/500 characters',
                    style: context.caption.copyWith(
                      color: value.text.length > 500
                          ? AppColors.error
                          : context.textSecondary,
                    ),
                  );
                },
              ),
              Spacing.gapXXL,
            ],
          ),
        ),
      ),
    );
  }
}
