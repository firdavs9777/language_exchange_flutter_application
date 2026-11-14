import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/main/sections/recommended_tile.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_feature_groups.dart';
import 'package:bananatalk_app/pages/learning/main/sections/study_features.dart';
import 'package:bananatalk_app/pages/learning/main/sections/vocab_packs_card.dart';
import 'package:bananatalk_app/pages/learning/main/study_hub_metrics.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Everything the hub's doors do not show (shown when `studyDoorsEnabled` is
/// on): the weak-area shortcut, vocabulary packs, and the feature groups minus
/// the tutor and roleplay (the Talk door's).
class StudyMoreScreen extends StatelessWidget {
  const StudyMoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    const m = StudyHubMetrics.pageMargin;
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(title: Text(l.studyDoorMore)),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Draws nothing until a weak area with enough attempts exists.
              RecommendedTile(),
              SizedBox(height: StudyHubMetrics.tileGap),
              VocabPacksCard(),
              SizedBox(height: StudyHubMetrics.groupGap),
              StudyFeatureGroups(
                exclude: {StudyFeature.tutor, StudyFeature.roleplay},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
