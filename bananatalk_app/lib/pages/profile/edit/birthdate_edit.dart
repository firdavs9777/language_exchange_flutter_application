import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/widgets/edit_screen_scaffold.dart';
import 'package:bananatalk_app/pages/profile/widgets/gradient_save_button.dart';
import 'package:bananatalk_app/pages/profile/widgets/profile_snackbar.dart';
import 'package:bananatalk_app/pages/profile/widgets/section_label.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Birthdate edit screen.
///
/// Mirrors the [ProfileInfoSet] (name+gender) edit pattern:
/// `EditScreenScaffold` + `GradientSaveButton` + `showProfileSnackBar`.
///
/// Backend enforces ≤3 changes per trailing 60-day window and a min age of
/// 13 (see `users.js#updateUser`). This screen reads
/// [Community.birthDateChangesAt] to mirror that quota client-side so the
/// user sees how many changes remain — and the Save button is disabled
/// (with an "available on …" message) once the cap is hit.
class BirthdateEdit extends ConsumerStatefulWidget {
  const BirthdateEdit({super.key, required this.user});

  final Community user;

  @override
  ConsumerState<BirthdateEdit> createState() => _BirthdateEditState();
}

class _BirthdateEditState extends ConsumerState<BirthdateEdit> {
  static const int _maxChanges = 3;
  static const Duration _window = Duration(days: 60);
  static const int _minAge = 13;
  static const int _maxAge = 100;

  late DateTime? _selectedDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _parseStoredDate();
  }

  DateTime? _parseStoredDate() {
    final y = int.tryParse(widget.user.birth_year);
    final m = int.tryParse(widget.user.birth_month);
    final d = int.tryParse(widget.user.birth_day);
    if (y == null || m == null || d == null) return null;
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  /// Count of changes that fall inside the trailing 60-day window. Anything
  /// older than 60 days has "rolled off" and doesn't count toward the cap.
  int get _recentChangeCount {
    final cutoff = DateTime.now().subtract(_window);
    return widget.user.birthDateChangesAt
        .where((t) => t.isAfter(cutoff))
        .length;
  }

  int get _remaining =>
      (_maxChanges - _recentChangeCount).clamp(0, _maxChanges);

  /// When the next change becomes available — the moment the *earliest*
  /// in-window timestamp rolls out of the 60-day window. Null if the user
  /// isn't currently rate-limited.
  DateTime? get _nextAvailableAt {
    if (_remaining > 0) return null;
    final cutoff = DateTime.now().subtract(_window);
    final inWindow =
        widget.user.birthDateChangesAt.where((t) => t.isAfter(cutoff)).toList()
          ..sort();
    if (inWindow.isEmpty) return null;
    return inWindow.first.add(_window);
  }

  bool get _hasChanges {
    final stored = _parseStoredDate();
    if (stored == null) return _selectedDate != null;
    if (_selectedDate == null) return false;
    return stored != _selectedDate;
  }

  bool get _canSave =>
      _hasChanges &&
      !_isSaving &&
      _selectedDate != null &&
      _remaining > 0 &&
      _isValidAge(_selectedDate!);

  bool _isValidAge(DateTime date) {
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age -= 1;
    }
    return age >= _minAge && age <= _maxAge;
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    final initial = _selectedDate ??
        DateTime(now.year - 20, now.month, now.day);
    final firstAllowed = DateTime(now.year - _maxAge, now.month, now.day);
    final lastAllowed = DateTime(now.year - _minAge, now.month, now.day);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstAllowed)
          ? firstAllowed
          : initial.isAfter(lastAllowed)
              ? lastAllowed
              : initial,
      firstDate: firstAllowed,
      lastDate: lastAllowed,
      helpText: AppLocalizations.of(context)!.birthdateSelectHelp,
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final l10n = AppLocalizations.of(context)!;
    HapticFeedback.lightImpact();
    setState(() => _isSaving = true);

    try {
      await ref.read(authServiceProvider).updateBirthDate(
            year: _selectedDate!.year,
            month: _selectedDate!.month,
            day: _selectedDate!.day,
          );
      ref.invalidate(userProvider);

      if (!mounted) return;
      showProfileSnackBar(
        context,
        message: l10n.profileUpdatedSuccessfully,
        type: ProfileSnackBarType.success,
      );
      Navigator.pop(context, _selectedDate);
    } on BirthdateRateLimitException catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showProfileSnackBar(
        context,
        message: e.nextAvailableAt != null
            ? l10n.birthdateRateLimitedUntil(_formatDate(e.nextAvailableAt!))
            : l10n.birthdateRateLimited,
        type: ProfileSnackBarType.error,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      showProfileSnackBar(
        context,
        message:
            '${l10n.failedToUpdate}: ${e.toString().replaceFirst('Exception: ', '')}',
        type: ProfileSnackBarType.error,
      );
    }
  }

  /// Formats [d] in the user's current locale (e.g. "Mar 15, 1995" in en,
  /// "15 мар. 1995 г." in ru). Falls back to a hard-coded English short
  /// format if the active locale's date data hasn't been initialised — a
  /// guard so a missing intl locale registration can't crash the screen.
  String _formatDate(DateTime d) {
    final locale = Localizations.localeOf(context).toString();
    try {
      return DateFormat.yMMMd(locale).format(d);
    } catch (_) {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLocked = _remaining == 0;
    final invalidAge =
        _selectedDate != null && !_isValidAge(_selectedDate!);

    return EditScreenScaffold(
      title: l10n.birthdate,
      canSave: _canSave,
      isSaving: _isSaving,
      onSave: _save,
      showBottomSaveButton: false,
      bodyPadding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            icon: Icons.cake_rounded,
            text: l10n.birthdate,
          ),
          const SizedBox(height: 10),
          _buildDateField(context),

          const SizedBox(height: 16),
          _buildQuotaBanner(context, isLocked: isLocked),

          if (invalidAge) ...[
            const SizedBox(height: 12),
            _buildInlineError(
              context,
              l10n.birthdateMinAgeError(_minAge),
            ),
          ],

          const SizedBox(height: 28),

          GradientSaveButton(
            canSave: _canSave,
            isSaving: _isSaving,
            onPressed: _save,
          ),

          if (_hasChanges && !isLocked) ...[
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 14,
                    color: context.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.unsavedChanges,
                    style: context.captionSmall
                        .copyWith(color: context.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Date field ─────────────────────────────────────────────────────────
  Widget _buildDateField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDate = _selectedDate != null;
    final isLocked = _remaining == 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLocked || _isSaving ? null : _pickDate,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : context.dividerColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: hasDate
                      ? AppColors.primary
                      : context.textMuted,
                  size: 22,
                ),
              ),
              Expanded(
                child: Text(
                  hasDate
                      ? _formatDate(_selectedDate!)
                      : AppLocalizations.of(context)!
                          .birthdateSelectPlaceholder,
                  style: context.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: hasDate
                        ? context.textPrimary
                        : context.textHint,
                  ),
                ),
              ),
              if (!isLocked)
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.textMuted,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Quota banner ───────────────────────────────────────────────────────
  Widget _buildQuotaBanner(BuildContext context, {required bool isLocked}) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isLocked ? AppColors.warning : AppColors.info;
    final next = _nextAvailableAt;

    final String text;
    if (isLocked && next != null) {
      text = '${l10n.birthdateQuotaLocked(_maxChanges)} '
          '${l10n.birthdateNextChangeOn(_formatDate(next))}';
    } else if (isLocked) {
      text = l10n.birthdateQuotaLocked(_maxChanges);
    } else {
      text = l10n.birthdateQuotaRemaining(_remaining, _maxChanges);
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.32 : 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isLocked
                ? Icons.lock_clock_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: context.captionSmall.copyWith(
                color: context.textSecondary,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineError(BuildContext context, String text) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: context.captionSmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
