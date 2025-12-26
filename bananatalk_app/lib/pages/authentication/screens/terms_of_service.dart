import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/widgets/banana_button.dart';
import 'package:bananatalk_app/widgets/banana_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TermsOfServiceScreen extends ConsumerStatefulWidget {
  const TermsOfServiceScreen({Key? key}) : super(key: key);

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
            'Please accept the Terms of Service to continue',
            BanaStyles: BananaTextStyles.warning,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call backend API to accept terms
      final authService = ref.read(authServiceProvider);
      final result = await authService.acceptTerms();
      final token = authService.token;
      print(result['success']);
      print(authService.token);
      print(result);

      if (!mounted) return;

      if (token.isNotEmpty) {
        // Terms accepted successfully - navigate back
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: BananaText(
              result['message'] ?? 'Error accepting terms. Please try again.',
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
            'Error accepting terms. Please try again.',
            BanaStyles: BananaTextStyles.error,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BananaText(
          'Terms of Service',
          BanaStyles: BananaTextStyles.appBarTitle,
        ),
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        automaticallyImplyLeading: false,
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
                    child: Image.asset(
                      'assets/images/logo_no_background.png',
                      height: 100,
                      width: 100,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  BananaText(
                    'End User License Agreement (EULA)',
                    BanaStyles: BananaTextStyles.heading,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'Last Updated: ${DateTime.now().year}',
                    BanaStyles: BananaTextStyles.caption,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Introduction
                  BananaText(
                    'Welcome to BananaTalk',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'By using BananaTalk, you agree to be bound by these Terms of Service. Please read them carefully before using our service.',
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
                              'Zero Tolerance Policy',
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
                          'BananaTalk has a ZERO TOLERANCE policy for objectionable content and abusive users. We do not permit, condone, or tolerate:',
                          BanaStyles: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBulletPoint(
                          'Harassment, bullying, or threats of any kind',
                        ),
                        _buildBulletPoint(
                          'Hate speech, discrimination, or content that promotes violence',
                        ),
                        _buildBulletPoint(
                          'Sexually explicit, pornographic, or inappropriate content',
                        ),
                        _buildBulletPoint(
                          'Spam, scams, or fraudulent activities',
                        ),
                        _buildBulletPoint(
                          'Impersonation or false representation',
                        ),
                        _buildBulletPoint(
                          'Any content that violates applicable laws or regulations',
                        ),
                        const SizedBox(height: 12),
                        BananaText(
                          'Users who violate these policies will be immediately banned from the platform. We reserve the right to remove any content and terminate any account that violates these terms without prior notice.',
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
                    'User-Generated Content',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'BananaTalk allows users to create and share content including messages, posts, images, and other materials. You are solely responsible for all content you create, upload, or share through the service.',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'By using BananaTalk, you agree that:',
                    BanaStyles: BananaTextStyles.boldText,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'You will not post objectionable, harmful, or illegal content',
                  ),
                  _buildBulletPoint(
                    'You will not engage in abusive behavior toward other users',
                  ),
                  _buildBulletPoint(
                    'You will respect the rights and dignity of all users',
                  ),
                  _buildBulletPoint(
                    'You will report any objectionable content or abusive users you encounter',
                  ),
                  const SizedBox(height: 24),

                  // Content Moderation
                  BananaText(
                    'Content Moderation',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'BananaTalk actively moderates user-generated content to maintain a safe and respectful environment. We use automated systems and human moderators to review and remove content that violates our policies.',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'If you encounter objectionable content or abusive behavior, please report it immediately using our in-app reporting features. We take all reports seriously and will investigate promptly.',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Account Responsibility
                  BananaText(
                    'Account Responsibility',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'You are responsible for maintaining the security of your account and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Prohibited Activities
                  BananaText(
                    'Prohibited Activities',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'In addition to the zero tolerance policy above, you agree not to:',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'Violate any applicable local, state, national, or international law',
                  ),
                  _buildBulletPoint(
                    'Infringe upon the rights of others, including intellectual property rights',
                  ),
                  _buildBulletPoint(
                    'Transmit any viruses, malware, or harmful code',
                  ),
                  _buildBulletPoint(
                    'Attempt to gain unauthorized access to the service or other accounts',
                  ),
                  _buildBulletPoint(
                    'Use the service for any commercial purpose without authorization',
                  ),
                  const SizedBox(height: 24),

                  // Termination
                  BananaText(
                    'Termination',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'We reserve the right to suspend or terminate your account at any time, with or without notice, for any violation of these Terms of Service, including but not limited to posting objectionable content or engaging in abusive behavior.',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Changes to Terms
                  BananaText(
                    'Changes to Terms',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'We may update these Terms of Service from time to time. Continued use of the service after changes constitutes acceptance of the updated terms.',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Contact
                  BananaText(
                    'Contact Us',
                    BanaStyles: BananaTextStyles.subheading,
                  ),
                  const SizedBox(height: 8),
                  BananaText(
                    'If you have questions about these Terms of Service or need to report a violation, please contact us through the app\'s support features.',
                    BanaStyles: BananaTextStyles.body,
                  ),
                  const SizedBox(height: 24),

                  // Acceptance Checkbox
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _hasAcceptedTerms,
                          onChanged: (value) {
                            setState(() {
                              _hasAcceptedTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _hasAcceptedTerms = !_hasAcceptedTerms;
                              });
                            },
                            child: BananaText(
                              'I have read and agree to the Terms of Service and understand that BananaTalk has zero tolerance for objectionable content and abusive users. I agree to comply with all terms and conditions outlined above.',
                              BanaStyles: BananaTextStyles.body,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Accept Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: BananaButton(
                  BananaText: BananaText(
                    _isLoading ? 'Processing...' : 'Accept and Continue',
                    BanaStyles: BananaTextStyles.buttonText,
                  ),
                  onPressed: _isLoading ? null : _acceptTerms,
                  color: _hasAcceptedTerms
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
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
