import 'package:flutter/material.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';

enum SocialProvider { apple, google, facebook }

/// Unified social-login button. Renders the platform-correct icon, brand
/// color, and label. The actual OAuth handling is left to the screen.
class SocialLoginButton extends StatelessWidget {
  final SocialProvider provider;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
    this.isLoading = false,
  });

  ({Color bg, Color fg, IconData icon, String label}) _style(
    BuildContext context,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (provider) {
      SocialProvider.apple => (
        bg: isDark ? Colors.white : Colors.black,
        fg: isDark ? Colors.black : Colors.white,
        icon: Icons.apple,
        label: 'Continue with Apple',
      ),
      SocialProvider.google => (
        bg: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        fg: isDark ? Colors.white : const Color(0xFF1F1F1F),
        icon: Icons.g_mobiledata_rounded,
        label: 'Continue with Google',
      ),
      SocialProvider.facebook => (
        bg: const Color(0xFF1877F2),
        fg: Colors.white,
        icon: Icons.facebook,
        label: 'Continue with Facebook',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final s = _style(context);
    final enabled = !isLoading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: enabled
            ? s.bg
            : context.dividerColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              border: provider == SocialProvider.google
                  ? Border.all(
                      color: context.dividerColor.withValues(alpha: 0.6),
                      width: 1,
                    )
                  : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(s.fg),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        s.icon,
                        color: s.fg,
                        size: provider == SocialProvider.google ? 28 : 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.label,
                        style: TextStyle(
                          color: s.fg,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
