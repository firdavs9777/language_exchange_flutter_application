import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SocialProvider { apple, google, email, facebook }

/// Unified social-login button with press-scale feedback and polished visuals.
class SocialLoginButton extends StatefulWidget {
  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<SocialLoginButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 180),
      value: 1.0,
    );
    _scaleAnim = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) {
    if (widget.onPressed == null || widget.isLoading) return;
    _pressController.animateTo(0.0);
  }

  void _onTapUp(_) => _pressController.animateTo(1.0);
  void _onTapCancel() => _pressController.animateTo(1.0);

  void _onTap() {
    if (widget.onPressed == null || widget.isLoading) return;
    HapticFeedback.lightImpact();
    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnim,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnim.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    return switch (widget.provider) {
      SocialProvider.google => _GoogleButton(isLoading: widget.isLoading),
      SocialProvider.apple => _AppleButton(isLoading: widget.isLoading),
      SocialProvider.email => _EmailButton(isLoading: widget.isLoading),
      SocialProvider.facebook => _FacebookButton(isLoading: widget.isLoading),
    };
  }
}

// ─── Google ──────────────────────────────────────────────────────────────────

class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  const _GoogleButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _GoogleGIcon(),
                const SizedBox(width: 12),
                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Color(0xFF1F1F1F),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}

class _GoogleGIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Background circle
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC04);
    const red = Color(0xFFEA4335);

    final strokeWidth = size.width * 0.18;
    final arcR = r - strokeWidth / 2 - 1;
    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: arcR);

    void drawArc(Color color, double start, double sweep) {
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }

    const pi = 3.14159265358979;
    // Draw the four colored arcs of the Google G
    drawArc(red, -pi / 2 + 0.1, pi * 0.55 - 0.05);    // top-right → right
    drawArc(yellow, pi * 0.05, pi * 0.5);               // right → bottom
    drawArc(green, pi * 0.55, pi * 0.5);                // bottom → left
    drawArc(blue, pi * 1.05, pi * 0.4);                 // left → top-left

    // White cutout for the horizontal G bar
    final barPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx + arcR * 0.08, cy),
      Offset(cx + arcR + strokeWidth / 2 + 1, cy),
      barPaint,
    );

    // Blue refill for the right half of the horizontal bar
    final barBluePaint = Paint()
      ..color = blue
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx + arcR * 0.08, cy),
      Offset(cx + arcR, cy),
      barBluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Apple ───────────────────────────────────────────────────────────────────

class _AppleButton extends StatelessWidget {
  final bool isLoading;
  const _AppleButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2A2A2A), Color(0xFF000000)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apple, color: Colors.white, size: 26),
                SizedBox(width: 10),
                Text(
                  'Continue with Apple',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Email ───────────────────────────────────────────────────────────────────

class _EmailButton extends StatelessWidget {
  final bool isLoading;
  const _EmailButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00BFA5), Color(0xFF00897B)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.38),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF00BFA5).withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email_rounded, color: Colors.white, size: 22),
                SizedBox(width: 10),
                Text(
                  'Continue with Email',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Facebook ────────────────────────────────────────────────────────────────

class _FacebookButton extends StatelessWidget {
  final bool isLoading;
  const _FacebookButton({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1877F2), Color(0xFF0C5FD6)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1877F2).withValues(alpha: 0.40),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: isLoading
          ? const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.facebook_rounded, color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'Continue with Facebook',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
    );
  }
}
