import 'dart:async';
import 'dart:io' show Platform;

import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/authentication/login/apple_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/google_login_screen.dart';
import 'package:bananatalk_app/pages/authentication/login/login_screen.dart';
import 'package:bananatalk_app/pages/authentication/widgets/animated_banana_title.dart';
import 'package:bananatalk_app/pages/authentication/widgets/social_login_button.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:flutter/material.dart';

// ─── Feature data ─────────────────────────────────────────────────────────────

class _Feature {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accent;
  const _Feature(this.emoji, this.title, this.subtitle, this.accent);
}

const _featureCount = 3;

List<_Feature> _buildFeatures(AppLocalizations l10n) => [
  _Feature(
    '🌍',
    l10n.authWelcomeFeatureConnectTitle,
    l10n.authWelcomeFeatureConnectSubtitle,
    const Color(0xFF00BFA5),
  ),
  _Feature(
    '🤖',
    l10n.authWelcomeFeatureLearnTitle,
    l10n.authWelcomeFeatureLearnSubtitle,
    const Color(0xFF7C4DFF),
  ),
  _Feature(
    '🚀',
    l10n.authWelcomeFeatureGrowTitle,
    l10n.authWelcomeFeatureGrowSubtitle,
    const Color(0xFFFF6F61),
  ),
];

// ─── HomePage ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    _autoAdvance = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _featureCount;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final l10n = AppLocalizations.of(context)!;
    final features = _buildFeatures(l10n);

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const Spacer(),
                      // ── Brand mark + title + tagline ──────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/images/logo_mark_ios.png',
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const AnimatedBananaTitle(fontSize: 40),
                      const SizedBox(height: 3),
                      Text(
                        l10n.authWelcomeTagline,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: context.textMuted,
                          letterSpacing: 2.8,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Feature carousel ────────────────────────────────
                      SizedBox(
                        height: 140,
                        child: PageView.builder(
                          controller: _pageCtrl,
                          itemCount: features.length,
                          onPageChanged: (i) => setState(() => _page = i),
                          itemBuilder: (context, i) {
                            final f = features[i];
                            final isActive = i == _page;
                            return AnimatedScale(
                              scale: isActive ? 1.0 : 0.92,
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOutCubic,
                              child: _FeatureCard(feature: f, isDark: isDark),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _PageDots(count: features.length, current: _page),
                      const SizedBox(height: 24),

                      // ── CTA + buttons ────────────────────────────────────
                      Text(
                        l10n.authWelcomeCtaTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.authWelcomeCtaSubtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (Platform.isIOS) ...[
                        SocialLoginButton(
                          provider: SocialProvider.apple,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AppleLogin(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      SocialLoginButton(
                        provider: SocialProvider.google,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const GoogleLogin(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SocialLoginButton(
                        provider: SocialProvider.email,
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Login()),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Feature card ─────────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final _Feature feature;
  final bool isDark;
  const _FeatureCard({required this.feature, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? feature.accent.withValues(alpha: 0.12)
        : feature.accent.withValues(alpha: 0.07);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: feature.accent.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: feature.accent.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            Text(feature.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: feature.accent,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page dots ────────────────────────────────────────────────────────────────

class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  const _PageDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF00BFA5)
                : const Color(0xFF00BFA5).withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
