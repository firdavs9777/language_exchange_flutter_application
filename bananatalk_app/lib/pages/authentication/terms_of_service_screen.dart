import 'package:flutter/foundation.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';

class TermsOfServiceScreen extends ConsumerStatefulWidget {
  /// If true, this is shown before registration (no token yet)
  /// Will just return true/false instead of making API call
  final bool? isPreRegistration;

  const TermsOfServiceScreen({Key? key, this.isPreRegistration})
    : super(key: key);

  @override
  ConsumerState<TermsOfServiceScreen> createState() =>
      _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends ConsumerState<TermsOfServiceScreen> {
  bool _hasAcceptedTerms = false;
  bool _isLoading = false;

  Future<void> _acceptTerms() async {
    if (!_hasAcceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            AppLocalizations.of(context)!.termsSnackAcceptFirst,
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // For pre-registration, just return true (terms will be recorded during registration)
    if (widget.isPreRegistration == true) {
      // Save local flag as fallback
      await _saveLocalTermsAccepted();
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend API to accept terms
      final authService = ref.read(authServiceProvider);
      final result = await authService.acceptTerms();

      if (!mounted) return;

      if (result['success'] == true) {
        // Save local flag as fallback
        await _saveLocalTermsAccepted();
        // Re-checked: the mounted guard above sits before this write, and
        // popping a disposed route throws.
        if (!mounted) return;
        // Terms accepted successfully - navigate back
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: BananaText(
              result['message'] ?? AppLocalizations.of(context)!.termsErrorAccepting,
              BanaStyles: BananaTextStyles.error,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BananaText(
            AppLocalizations.of(context)!.termsErrorAccepting,
            BanaStyles: BananaTextStyles.error,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Save local flag to SharedPreferences as fallback when backend doesn't save it
  Future<void> _saveLocalTermsAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('termsAcceptedLocally', true);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BananaText(
          AppLocalizations.of(context)!.termsOfService,
          BanaStyles: BananaTextStyles.appBarTitle,
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Center(
                    child: Text(
                      'Bananatalk',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  BananaText(
                    AppLocalizations.of(context)!.termsEulaTitle,
                    BanaStyles: BananaTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsLastUpdated(DateTime.now().year),
                    BanaStyles: BananaTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Introduction
                  BananaText(
                    AppLocalizations.of(context)!.termsWelcomeHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsWelcomeBody,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Zero Tolerance Section - CRITICAL FOR APP STORE
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            BananaText(
                              AppLocalizations.of(context)!.termsZeroToleranceHeading,
                              BanaStyles: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        BananaText(
                          AppLocalizations.of(context)!.termsZeroToleranceIntro,
                          BanaStyles: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.termsZeroToleranceItem1,
                        ),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.termsZeroToleranceItem2,
                        ),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.termsZeroToleranceItem3,
                        ),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.termsZeroToleranceItem4,
                        ),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.termsZeroToleranceItem5,
                        ),
                        _buildBulletPoint(
                          AppLocalizations.of(context)!.termsZeroToleranceItem6,
                        ),
                        const SizedBox(height: 12),
                        BananaText(
                          AppLocalizations.of(context)!.termsZeroToleranceEnforcement,
                          BanaStyles: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User-Generated Content
                  BananaText(
                    AppLocalizations.of(context)!.termsUgcHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsUgcBody,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsUgcAgreeIntro,
                    BanaStyles: BananaTextStyles.boldText,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsUgcItem1,
                  ),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsUgcItem2,
                  ),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsUgcItem3,
                  ),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsUgcItem4,
                  ),
                  const SizedBox(height: 24),

                  // Content Moderation
                  BananaText(
                    AppLocalizations.of(context)!.termsModerationHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsModerationBody,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsModerationReport,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Account Responsibility
                  BananaText(
                    AppLocalizations.of(context)!.termsAccountHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsAccountBody,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Prohibited Activities
                  BananaText(
                    AppLocalizations.of(context)!.termsProhibitedHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsProhibitedIntro,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsProhibitedItem1,
                  ),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsProhibitedItem2,
                  ),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsProhibitedItem3,
                  ),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsProhibitedItem4,
                  ),
                  _buildBulletPoint(
                    AppLocalizations.of(context)!.termsProhibitedItem5,
                  ),
                  const SizedBox(height: 24),

                  // Termination
                  BananaText(
                    AppLocalizations.of(context)!.termsTerminationHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsTerminationBody,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Changes to Terms
                  BananaText(
                    AppLocalizations.of(context)!.termsChangesHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsChangesBody,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Contact
                  BananaText(
                    AppLocalizations.of(context)!.termsContactHeading,
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    AppLocalizations.of(context)!.termsContactBody,
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Fixed bottom section - Checkbox and Accept Button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Acceptance Checkbox - Always visible
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _hasAcceptedTerms = !_hasAcceptedTerms;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _hasAcceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  _hasAcceptedTerms = value ?? false;
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.termsAgreeCheckbox,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Accept Button
                  SizedBox(
                    width: double.infinity,
                    child: BananaButton(
                      BananaText: BananaText(
                        _isLoading ? AppLocalizations.of(context)!.termsProcessing : AppLocalizations.of(context)!.termsAcceptAndContinue,
                        BanaStyles: BananaTextStyles.buttonText,
                      ),
                      onPressed: _isLoading ? null : _acceptTerms,
                      color: _hasAcceptedTerms
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BananaText('• ', BanaStyles: BananaTextStyles.body),
          Expanded(child: BananaText(text, BanaStyles: BananaTextStyles.body)),
        ],
      ),
    );
  }
}
