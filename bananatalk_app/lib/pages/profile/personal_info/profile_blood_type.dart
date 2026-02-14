import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonBloodType extends ConsumerStatefulWidget {
  final String currentSelectedBloodType;
  const PersonBloodType({super.key, required this.currentSelectedBloodType});

  @override
  _PersonBloodTypeState createState() => _PersonBloodTypeState();
}

class _PersonBloodTypeState extends ConsumerState<PersonBloodType> {
  // List of blood types
  final List<String> bloodTypes = [
    'Type A',
    'Type B',
    'Type AB',
    'Type O',
    'Type A-',
    'Type B-',
    'Type AB-',
    'Type O-'
  ];

  // Variable to store the selected blood type
  late String selectedBloodType;

  @override
  void initState() {
    super.initState();
    selectedBloodType = widget.currentSelectedBloodType;
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
          'My Blood Type',
          style: context.titleLarge,
        ),
      ),
      body: Padding(
        padding: Spacing.screenPadding,
        child: Column(
          children: [
            // Displaying the blood type options in a grid layout with 4 items per row
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 items per row
                  crossAxisSpacing: 10, // Horizontal space between items
                  mainAxisSpacing: 10, // Vertical space between items
                ),
                itemCount: bloodTypes.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedBloodType == bloodTypes[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBloodType =
                            bloodTypes[index]; // Update selected blood type
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.primaryColor // Selected color
                            : context.containerColor, // Default color
                        borderRadius: AppRadius.borderSM,
                        border: Border.all(
                          color: isSelected
                              ? context.primaryColor // Border color when selected
                              : context.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bloodTypes[index],
                        style: context.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? context.textOnPrimary // White text when selected
                              : context.textPrimary, // Black text when not selected
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Save Button
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedBloodType.isNotEmpty) {
                    await ref
                        .read(authServiceProvider)
                        .updateUserBloodType(bloodType: selectedBloodType);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved: $selectedBloodType')),
                    );
                    Navigator.of(context).pop(selectedBloodType);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a blood type')),
                    );
                  }
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
                  'Save',
                  style: context.titleMedium.copyWith(
                    color: AppColors.gray900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
