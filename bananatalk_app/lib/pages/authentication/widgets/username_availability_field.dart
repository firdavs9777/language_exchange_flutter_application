import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

enum _AvailabilityState {
  empty,
  invalidFormat,
  checking,
  available,
  taken,
  reserved,
  networkError,
}

/// Optional username field with live availability check.
/// Format validation runs client-side first; network calls only fire after
/// format passes (regex /^[a-z0-9_]{3,20}$/). Debounced 500ms.
class UsernameAvailabilityField extends StatefulWidget {
  final TextEditingController controller;
  final void Function(bool isAvailable) onAvailabilityChanged;

  const UsernameAvailabilityField({
    super.key,
    required this.controller,
    required this.onAvailabilityChanged,
  });

  @override
  State<UsernameAvailabilityField> createState() =>
      _UsernameAvailabilityFieldState();
}

class _UsernameAvailabilityFieldState extends State<UsernameAvailabilityField> {
  static final RegExp _formatRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  Timer? _debounce;
  _AvailabilityState _state = _AvailabilityState.empty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChange);
    _debounce?.cancel();
    super.dispose();
  }

  void _onTextChange() {
    final raw = widget.controller.text.trim().toLowerCase();
    _debounce?.cancel();

    if (raw.isEmpty) {
      _setState(_AvailabilityState.empty);
      // Empty is treated as "ok to skip"
      widget.onAvailabilityChanged(true);
      return;
    }

    if (!_formatRegex.hasMatch(raw)) {
      _setState(_AvailabilityState.invalidFormat);
      widget.onAvailabilityChanged(false);
      return;
    }

    _setState(_AvailabilityState.checking);
    widget.onAvailabilityChanged(false);

    _debounce = Timer(const Duration(milliseconds: 500), () => _check(raw));
  }

  void _setState(_AvailabilityState s) {
    if (mounted && _state != s) setState(() => _state = s);
  }

  Future<void> _check(String value) async {
    try {
      final res = await http
          .get(Uri.parse(
              '${Endpoints.baseURL}users/check-username?value=$value'))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;
      // Stale check — text changed since this fired.
      if (widget.controller.text.trim().toLowerCase() != value) return;

      if (res.statusCode != 200) {
        _setState(_AvailabilityState.networkError);
        widget.onAvailabilityChanged(true); // soft-allow on backend hiccup
        return;
      }

      final body = json.decode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final available = data?['available'] as bool? ?? false;
      final reason = data?['reason'] as String?;

      if (available) {
        _setState(_AvailabilityState.available);
        widget.onAvailabilityChanged(true);
      } else if (reason == 'taken') {
        _setState(_AvailabilityState.taken);
        widget.onAvailabilityChanged(false);
      } else if (reason == 'reserved') {
        _setState(_AvailabilityState.reserved);
        widget.onAvailabilityChanged(false);
      } else {
        _setState(_AvailabilityState.invalidFormat);
        widget.onAvailabilityChanged(false);
      }
    } catch (_) {
      if (!mounted) return;
      // Stale guard — text changed during the request.
      if (widget.controller.text.trim().toLowerCase() != value) return;
      _setState(_AvailabilityState.networkError);
      // Soft-allow on network failure; backend re-validates on register.
      widget.onAvailabilityChanged(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.none,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          style: context.bodyLarge.copyWith(fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            labelText: l10n.usernameOptional,
            hintText: l10n.usernameHint,
            hintStyle: context.bodyMedium.copyWith(color: context.textHint),
            prefixIcon: Icon(
              Icons.alternate_email_rounded,
              color: context.textMuted,
            ),
            suffixIcon: _suffixIcon(),
            filled: true,
            fillColor: context.surfaceColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.dividerColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: context.dividerColor.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        if (_helperText(l10n) != null) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _helperText(l10n)!,
              style: context.captionSmall.copyWith(
                color: _helperColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget? _suffixIcon() {
    return switch (_state) {
      _AvailabilityState.empty => null,
      _AvailabilityState.invalidFormat ||
      _AvailabilityState.taken ||
      _AvailabilityState.reserved =>
        Icon(Icons.close_rounded, color: AppColors.error),
      _AvailabilityState.checking => const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      _AvailabilityState.available =>
        const Icon(Icons.check_rounded, color: AppColors.success),
      _AvailabilityState.networkError => null,
    };
  }

  String? _helperText(AppLocalizations l10n) {
    return switch (_state) {
      _AvailabilityState.empty ||
      _AvailabilityState.checking ||
      _AvailabilityState.networkError =>
        null,
      _AvailabilityState.invalidFormat => l10n.usernameInvalidFormat,
      _AvailabilityState.available => l10n.usernameAvailable,
      _AvailabilityState.taken => l10n.usernameTaken,
      _AvailabilityState.reserved => l10n.usernameNotAvailable,
    };
  }

  Color _helperColor() {
    return switch (_state) {
      _AvailabilityState.available => AppColors.success,
      _ => AppColors.error,
    };
  }
}
