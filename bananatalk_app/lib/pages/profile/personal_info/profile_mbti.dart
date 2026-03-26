import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MBTIEdit extends ConsumerStatefulWidget {
  final String currentMBTI;
  const MBTIEdit({super.key, required this.currentMBTI});

  @override
  MBTIEditState createState() => MBTIEditState();
}

class MBTIEditState extends ConsumerState<MBTIEdit> {
  final List<String> mbtiList = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];

  late String selectedMBTI;

  @override
  void initState() {
    super.initState();
    selectedMBTI = widget.currentMBTI.isEmpty ? '' : widget.currentMBTI;
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
          l10n.selectYourMbti,
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
                itemCount: mbtiList.length,
                itemBuilder: (context, index) {
                  final isSelected = selectedMBTI == mbtiList[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMBTI = mbtiList[index];
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.primaryColor
                            : context.containerColor,
                        borderRadius: AppRadius.borderSM,
                        border: Border.all(
                          color: isSelected
                              ? context.primaryColor
                              : context.dividerColor,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        mbtiList[index],
                        style: context.labelLarge.copyWith(
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
                  await ref
                      .read(authServiceProvider)
                      .updateUserMbti(mbti: selectedMBTI);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.saved}: $selectedMBTI')),
                  );
                  Navigator.of(context).pop(selectedMBTI);
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
