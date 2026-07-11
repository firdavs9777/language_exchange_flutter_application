import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Row of single-digit boxes for OTP / verification-code entry.
///
/// A single hidden [TextField] captures all keyboard/paste input (so paste
/// naturally splits digits across boxes), while [length] visible boxes
/// render the current digits and reflect focus state.
///
/// Call [onCompleted] once the entered value reaches [length] characters.
/// On invalid-code feedback, use a [GlobalKey<OtpCodeFieldState>] to invoke
/// [OtpCodeFieldState.shakeAndClear].
class OtpCodeField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;

  const OtpCodeField({
    super.key,
    required this.length,
    required this.onCompleted,
  });

  @override
  State<OtpCodeField> createState() => OtpCodeFieldState();
}

class OtpCodeFieldState extends State<OtpCodeField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  String _value = '';

  /// Current digits entered so far (may be shorter than [OtpCodeField.length]
  /// if the user hasn't finished typing). Lets callers — e.g. a manual
  /// "Verify" button — read the in-progress code instead of only reacting to
  /// [OtpCodeField.onCompleted].
  String get value => _value;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _onChanged(String raw) {
    // Keep only digits, cap at the configured length. This is what allows a
    // multi-digit paste to populate every box in one shot.
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final capped = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;
    if (capped != raw) {
      _controller.value = TextEditingValue(
        text: capped,
        selection: TextSelection.collapsed(offset: capped.length),
      );
    }
    setState(() => _value = capped);
    if (capped.length == widget.length) {
      widget.onCompleted(capped);
    }
  }

  /// Plays a brief horizontal shake (e.g. after an invalid-code response)
  /// and clears the entered digits so the user can retry.
  void shakeAndClear() {
    if (!mounted) return;
    _shakeController.forward(from: 0).then((_) {
      if (!mounted) return;
      _shakeController.reset();
    });
    _controller.clear();
    setState(() => _value = '');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final progress = disableAnimations ? 0.0 : _shakeAnimation.value;
              final offset = _shakeOffset(progress);
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(widget.length, (index) {
                final hasFocus = _focusNode.hasFocus && index == _value.length;
                final filled = index < _value.length;
                final char = filled ? _value[index] : '';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _OtpBox(char: char, focused: hasFocus, theme: theme),
                );
              }),
            ),
          ),
          // Invisible field that actually receives keyboard/paste input.
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: widget.length * 56.0,
              height: 56,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: false,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: widget.length,
                showCursor: false,
                decoration: const InputDecoration(counterText: ''),
                onChanged: _onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _shakeOffset(double t) {
    if (t <= 0) return 0;
    // A few damped oscillations across the 300ms duration.
    const amplitude = 8.0;
    final decay = 1 - t;
    return amplitude * decay * math.sin(t * 4 * math.pi);
  }
}

const _kTealFocus = Color(0xFF00BFA5);

class _OtpBox extends StatelessWidget {
  final String char;
  final bool focused;
  final ThemeData theme;

  const _OtpBox({
    required this.char,
    required this.focused,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = focused
        ? _kTealFocus
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.6);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: focused ? 2 : 1),
      ),
      child: Text(
        char,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
