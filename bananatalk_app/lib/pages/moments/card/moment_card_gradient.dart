import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter/material.dart';

/// Renders the gradient text card for moments with a backgroundColor set and
/// no images/video. Pure render — no state.
class MomentCardGradient extends StatelessWidget {
  final Moments moment;

  const MomentCardGradient({super.key, required this.moment});

  @override
  Widget build(BuildContext context) {
    final colors = MomentGradients.getColors(
      moment.backgroundColor.isNotEmpty
          ? moment.backgroundColor
          : MomentGradients.defaultGradient,
    );
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.map((c) => Color(c)).toList(),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          moment.description,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
          maxLines: 10,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
