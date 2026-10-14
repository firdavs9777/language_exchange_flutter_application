import 'package:flutter/material.dart';

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/learning/exam_study/exam_study_tab.dart';

/// Exam Study as a pushed screen, for the hub's Exam prep tile. The legacy
/// hub still embeds [ExamStudyTab] as its third sub-tab.
class ExamStudyScreen extends StatelessWidget {
  const ExamStudyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.examStudy)),
        body: const ExamStudyTab(),
      );
}
