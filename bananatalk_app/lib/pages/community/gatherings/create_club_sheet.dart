import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// Create a club — the primary entity.
///
/// A club is keyed on a LANGUAGE plus an optional free-text interest, and
/// deliberately not on a city. Measured across 790 active users: 432 distinct
/// cities, ten with five or more active users, one with ten, none with twenty
/// — about 1.8 per city. Seoul has four. By language the same idea works: 49
/// active Korean learners, 586 native Chinese speakers. The interest field is
/// what still makes it a club ("running", "HSK4", "K-pop") rather than a
/// language filter.
class CreateClubSheet extends StatefulWidget {
  const CreateClubSheet({
    super.key,
    required this.defaultLanguage,
    this.apiClient,
  });

  final String defaultLanguage;
  final GatheringApiClient? apiClient;

  @override
  State<CreateClubSheet> createState() => _CreateClubSheetState();
}

class _CreateClubSheetState extends State<CreateClubSheet> {
  late final GatheringApiClient _api = widget.apiClient ?? GatheringApiClient();
  final _name = TextEditingController();
  final _interest = TextEditingController();
  final _description = TextEditingController();
  late final TextEditingController _language = TextEditingController(
    text: widget.defaultLanguage,
  );
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _interest.dispose();
    _description.dispose();
    _language.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    final language = _language.text.trim();

    if (name.isEmpty) {
      showCommunitySnackBar(
        context,
        message: l10n.clubNeedsName,
        type: CommunitySnackBarType.error,
      );
      return;
    }
    if (language.isEmpty) {
      showCommunitySnackBar(
        context,
        message: l10n.gatheringNeedsLanguage,
        type: CommunitySnackBarType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await _api.createClub(
      name: name,
      language: language,
      interest: _interest.text.trim(),
      description: _description.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!result.success) {
      showCommunitySnackBar(
        context,
        message: result.error!,
        type: CommunitySnackBarType.error,
      );
      return;
    }
    Navigator.of(context).pop(result.value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: Spacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: AppRadius.borderRound,
              ),
            ),
          ),
          Spacing.gapLG,
          Text(l10n.clubCreateTitle, style: context.titleLarge),
          Spacing.gapSM,
          Text(
            l10n.clubCreateSubtitle,
            style: context.bodySmall.copyWith(color: context.textSecondary),
          ),
          Spacing.gapLG,
          TextField(
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.clubNameLabel,
              counterText: '',
              border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
            ),
          ),
          Spacing.gapMD,
          TextField(
            controller: _language,
            decoration: InputDecoration(
              labelText: l10n.gatheringLanguageLabel,
              border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
            ),
          ),
          Spacing.gapMD,
          TextField(
            controller: _interest,
            maxLength: 60,
            decoration: InputDecoration(
              labelText: l10n.clubInterestLabel,
              helperText: l10n.clubInterestHint,
              counterText: '',
              border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
            ),
          ),
          Spacing.gapMD,
          TextField(
            controller: _description,
            maxLines: 3,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.clubDescriptionLabel,
              counterText: '',
              border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
            ),
          ),
          Spacing.gapLG,
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.clubCreate),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the club form as a bottom sheet. Returns the created club, or null.
Future<Club?> showCreateClubSheet(
  BuildContext context, {
  required String defaultLanguage,
}) {
  return showModalBottomSheet<Club>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => SingleChildScrollView(
      child: CreateClubSheet(defaultLanguage: defaultLanguage),
    ),
  );
}
