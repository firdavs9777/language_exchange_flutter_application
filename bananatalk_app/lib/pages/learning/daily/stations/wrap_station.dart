import 'package:flutter/material.dart';
import 'package:bananatalk_app/models/learning/daily_pack_model.dart';
import 'package:bananatalk_app/pages/learning/daily/stations/station_scaffold.dart';

/// Friday's quiz over the whole week's theme. Formative, never a gate on
/// advancing to the next theme.
class WrapStation extends StatelessWidget {
  final WrapPayload payload;
  final SubmitAnswers onSubmit;
  final VoidCallback onDone;

  const WrapStation({
    super.key,
    required this.payload,
    required this.onSubmit,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) => CheckSequence(
        checks: payload.questions,
        onSubmit: onSubmit,
        onDone: onDone,
      );
}
