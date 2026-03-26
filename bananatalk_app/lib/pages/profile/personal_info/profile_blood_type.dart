import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
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
    'Type A', 'Type B', 'Type AB', 'Type O',
    'Type A-', 'Type B-', 'Type AB-', 'Type O-'
  ];

  late String selectedBloodType;

  @override
  void initState() {
    super.initState();
    selectedBloodType = widget.currentSelectedBloodType;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: Text(
          l10n.myBloodType,
          style: context.titleLarge,
        ),
      ),
      body: Padding(
        padding: Spacing.screenPadding,
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: bloodTypes.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedBloodType == bloodTypes[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBloodType = bloodTypes[index];
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.primaryColor
                            : context.containerColor,
                        borderRadius: AppRadius.borderSM,
                        border: Border.all(
                          color: isSelected
                              ? context.primaryColor
                              : context.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bloodTypes[index],
                        style: context.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? context.textOnPrimary
                              : context.textPrimary,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  if (selectedBloodType.isNotEmpty) {
                    await ref
                        .read(authServiceProvider)
                        .updateUserBloodType(bloodType: selectedBloodType);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${l10n.saved}: $selectedBloodType')),
                    );
                    Navigator.of(context).pop(selectedBloodType);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.pleaseSelectABloodType)),
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
                  l10n.save,
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
