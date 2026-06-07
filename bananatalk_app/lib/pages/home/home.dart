import 'dart:async';
import 'dart:io' show Platform;

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

const _features = [
  _Feature('🌍', 'Connect', 'Meet language partners from 150+ countries around the world', Color(0xFF00BFA5)),
  _Feature('🤖', 'Learn', 'AI tutor, quizzes & pronunciation training — all in one app', Color(0xFF7C4DFF)),
  _Feature('🚀', 'Grow', 'Build real fluency through daily conversations and community', Color(0xFFFF6F61)),
];

// ─── HomePage ─────────────────────────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  int _page = 0;
  Timer? _autoAdvance;

  @override
  void initState() {
    super.initState();
    _autoAdvance = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _features.length;
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

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top: title + tagline ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Column(
                children: [
                  const AnimatedBananaTitle(fontSize: 40),
                  const SizedBox(height: 3),
                  Text(
                    'MEET  ·  CHAT  ·  CONNECT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: context.textMuted,
                      letterSpacing: 2.8,
                    ),
                  ),
                ],
              ),
            ),

            // ── Middle: feature carousel ────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 140,
                    child: PageView.builder(
                      controller: _pageCtrl,
                      itemCount: _features.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) {
                        final f = _features[i];
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
                  const SizedBox(height: 10),
                  _PageDots(count: _features.length, current: _page),
                ],
              ),
            ),

            // ── Bottom: CTA + buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Make global friends on Bananatalk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Join millions of language learners today',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Apple (iOS only)
                  if (Platform.isIOS) ...[
                    SocialLoginButton(
                      provider: SocialProvider.apple,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AppleLogin()),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Google
                  SocialLoginButton(
                    provider: SocialProvider.google,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GoogleLogin()),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Email
                  SocialLoginButton(
                    provider: SocialProvider.email,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Login()),
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
