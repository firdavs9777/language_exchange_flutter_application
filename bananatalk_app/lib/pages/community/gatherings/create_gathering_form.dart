import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/models/community/gathering_model.dart';
import 'package:bananatalk_app/services/gathering_api_client.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/pages/community/widgets/community_snackbar.dart';
import 'package:bananatalk_app/utils/gathering_time.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

/// The create form, used in two places: as a bottom sheet from the "+"
/// button, and **inline as the empty state**.
///
/// That second use is the point. Day one has zero gatherings, and an empty
/// list is the exact impression that killed voice rooms 93 times. So the
/// empty state is a pre-filled draft rather than an apology: the viewer's
/// target language, tomorrow evening in their own zone, six seats, quorum of
/// three — everything already filled in, one tap to post. At this scale most
/// gatherings will be created by people who came looking for one.
class CreateGatheringForm extends StatefulWidget {
  const CreateGatheringForm({
    super.key,
    required this.defaultLanguage,
    this.clubId,
    this.onCreated,
    this.compact = false,
    this.now,
  });

  /// The viewer's target language, pre-filled. Empty falls back to a free
  /// text field with nothing in it, which is the only case where the form
  /// cannot be posted in one tap.
  final String defaultLanguage;

  /// When set, the gathering is hung off this club. The backend refuses this
  /// for non-members, so only offer it where the viewer has joined.
  final String? clubId;

  final ValueChanged<Gathering>? onCreated;

  /// Inline (empty-state) rendering drops the sheet's grabber and title.
  final bool compact;

  /// Injectable clock for the "tomorrow evening" default.
  final DateTime? now;

  @override
  State<CreateGatheringForm> createState() => _CreateGatheringFormState();
}

class _CreateGatheringFormState extends State<CreateGatheringForm> {
  final _api = GatheringApiClient();
  late final TextEditingController _title;
  late final TextEditingController _language;
  late DateTime _startsAt;

  int _capacity = 6;
  int _quorum = 3;
  static const int _duration = 60;
  bool _submitting = false;

  /// Set once the user edits the title by hand, after which the language
  /// picker stops rewriting it underneath them.
  bool _titleTouched = false;

  @override
  void initState() {
    super.initState();
    _language = TextEditingController(text: widget.defaultLanguage);
    _title = TextEditingController();
    _startsAt = defaultGatheringStart(widget.now ?? DateTime.now());
    _title.addListener(() {
      if (_title.text.isNotEmpty) _titleTouched = true;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seeded here rather than in initState because it needs localizations.
    if (!_titleTouched && _title.text.isEmpty && _language.text.isNotEmpty) {
      _title.text = AppLocalizations.of(
        context,
      )!.gatheringDefaultTitle(_language.text);
      _titleTouched = false;
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _language.dispose();
    super.dispose();
  }

  Future<void> _pickWhen() async {
    final l10n = AppLocalizations.of(context)!;
    final now = widget.now ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      helpText: l10n.gatheringWhenLabel,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    final language = _language.text.trim();

    if (title.isEmpty) {
      showCommunitySnackBar(
        context,
        message: l10n.gatheringNeedsTitle,
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
    // The backend refuses a past start too; catching it here saves a round
    // trip and, more to the point, an error message for something the person
    // can see on screen.
    if (!_startsAt.isAfter(widget.now ?? DateTime.now())) {
      showCommunitySnackBar(
        context,
        message: l10n.gatheringNeedsFuture,
        type: CommunitySnackBarType.error,
      );
      return;
    }

    setState(() => _submitting = true);
    final result = await _api.createGathering(
      title: title,
      language: language,
      startsAt: _startsAt,
      durationMinutes: _duration,
      capacity: _capacity,
      // A quorum above capacity can never be met, so it is clamped rather
      // than left to produce a gathering that is permanently unconfirmable.
      quorum: _quorum > _capacity ? _capacity : _quorum,
      clubId: widget.clubId,
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

    showCommunitySnackBar(
      context,
      message: l10n.gatheringPosted,
      type: CommunitySnackBarType.success,
    );
    widget.onCreated?.call(result.value!);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: EdgeInsets.only(
        left: Spacing.lg,
        right: Spacing.lg,
        top: widget.compact ? 0 : Spacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + Spacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.compact) ...[
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
            Text(l10n.gatheringCreateTitle, style: context.titleLarge),
            Spacing.gapSM,
            Text(
              l10n.gatheringCreateSubtitle,
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
            Spacing.gapLG,
          ],
          TextField(
            controller: _title,
            maxLength: 120,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.gatheringTitleLabel,
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
          InkWell(
            onTap: _pickWhen,
            borderRadius: AppRadius.borderMD,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.gatheringWhenLabel,
                border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    size: 18,
                    color: context.primaryColor,
                  ),
                  Spacing.hGapSM,
                  Expanded(
                    child: Text(
                      '${_startsAt.day}/${_startsAt.month} · '
                      '${formatLocalClock(_startsAt)}',
                      style: context.bodyMedium,
                    ),
                  ),
                  Icon(Icons.edit_rounded, size: 16, color: context.textMuted),
                ],
              ),
            ),
          ),
          Spacing.gapMD,
          Row(
            children: [
              Expanded(
                child: _stepper(
                  context,
                  label: l10n.gatheringSeatsLabel,
                  value: _capacity,
                  min: 2,
                  max: 20,
                  onChanged: (v) => setState(() {
                    _capacity = v;
                    if (_quorum > _capacity) _quorum = _capacity;
                  }),
                ),
              ),
              Spacing.hGapMD,
              Expanded(
                child: _stepper(
                  context,
                  label: l10n.gatheringQuorumLabel,
                  value: _quorum,
                  min: 2,
                  max: _capacity,
                  onChanged: (v) => setState(() => _quorum = v),
                ),
              ),
            ],
          ),
          Spacing.gapSM,
          Text(
            // Says out loud what the host is signing up for: they are
            // attendee number one and they count toward the number below.
            l10n.gatheringQuorumExplainer,
            style: context.captionSmall.copyWith(color: context.textMuted),
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
                  : Text(l10n.gatheringPost),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepper(
    BuildContext context, {
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: AppRadius.borderMD),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: Spacing.xs,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded, size: 18),
          ),
          Text('$value', style: context.titleMedium),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

/// Opens the create form as a bottom sheet. Returns the created gathering, or
/// null if the sheet was dismissed.
Future<Gathering?> showCreateGatheringSheet(
  BuildContext context, {
  required String defaultLanguage,
  String? clubId,
}) {
  return showModalBottomSheet<Gathering>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) => SingleChildScrollView(
      child: CreateGatheringForm(
        defaultLanguage: defaultLanguage,
        clubId: clubId,
        onCreated: (g) => Navigator.of(sheetContext).pop(g),
      ),
    ),
  );
}
