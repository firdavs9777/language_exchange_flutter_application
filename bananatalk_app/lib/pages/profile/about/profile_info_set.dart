import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileInfoSet extends ConsumerStatefulWidget {
  final String userName;
  final String gender;
  const ProfileInfoSet({super.key, required this.userName, this.gender = ''});

  @override
  ConsumerState<ProfileInfoSet> createState() => _ProfileInfoSetState();
}

class _ProfileInfoSetState extends ConsumerState<ProfileInfoSet> {
  late TextEditingController _controllerName;
  late String? _selectedGender;
  final List<String?> _genders = ['Male', 'Female', 'Other'];

  // Convert backend lowercase to display format
  String? _convertGenderToDisplay(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    final lowerGender = gender.toLowerCase();
    if (lowerGender == 'male') return 'Male';
    if (lowerGender == 'female') return 'Female';
    if (lowerGender == 'other') return 'Other';
    return null;
  }

  // Convert display format back to backend lowercase
  String? _convertGenderToBackend(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    return gender.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _controllerName = TextEditingController(text: widget.userName);
    _selectedGender = _convertGenderToDisplay(widget.gender);
  }

  @override
  void dispose() {
    _controllerName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          'Edit Profile Name',
          style: context.titleLarge,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: Spacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: AppRadius.borderMD,
                boxShadow: AppShadows.sm,
              ),
              child: TextField(
                controller: _controllerName,
                style: context.bodyLarge,
                decoration: InputDecoration(
                  labelText: 'Enter your name',
                  labelStyle: context.bodyMedium.copyWith(
                    color: context.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.borderMD,
                    borderSide: BorderSide(color: context.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderMD,
                    borderSide: BorderSide(color: context.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.borderMD,
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  filled: true,
                  fillColor: context.cardBackground,
                  contentPadding: Spacing.paddingLG,
                ),
              ),
            ),
            Spacing.gapXL,
            Container(
              decoration: BoxDecoration(
                color: context.cardBackground,
                borderRadius: AppRadius.borderXL,
                boxShadow: AppShadows.sm,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  isDense: true,
                  menuMaxHeight: 400,
                  value: _selectedGender,
                  style: context.bodyLarge,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGender = newValue!;
                    });
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: context.cardBackground,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: context.dividerColor),
                      borderRadius: AppRadius.borderXL,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: context.dividerColor),
                      borderRadius: AppRadius.borderXL,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      borderRadius: AppRadius.borderXL,
                    ),
                    labelText: 'Gender (Required)',
                    labelStyle: context.bodyMedium.copyWith(
                      color: context.textSecondary,
                    ),
                    hintText: 'Select your gender',
                    hintStyle: context.bodyMedium.copyWith(
                      color: context.textHint,
                    ),
                    prefixIcon: Icon(Icons.person, color: context.iconColor),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  items: _genders.map<DropdownMenuItem<String>>((String? gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(
                        gender ?? 'Select gender',
                        style: context.bodyMedium,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Spacing.gapXL,
            ElevatedButton(
              onPressed: () async {
                // Convert display gender back to backend format (lowercase)
                final backendGender = _convertGenderToBackend(_selectedGender);
                await ref.read(authServiceProvider).updateUserName(
                    userName: _controllerName.text, gender: backendGender);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Saved: ${_controllerName.text} ${_selectedGender ?? "N/A"}'),
                    duration: const Duration(seconds: 3),
                  ),
                );

                Navigator.pop(context, {
                  'userName': _controllerName.text,
                  'gender': backendGender ?? ''
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.gray900,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AppRadius.borderMD,
                ),
              ),
              child: Text(
                'Update',
                style: context.titleMedium.copyWith(
                  color: AppColors.gray900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
