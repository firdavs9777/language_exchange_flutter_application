import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/pages/profile/edit_main/completion_calculator.dart';
import 'package:bananatalk_app/pages/profile/edit_main/sections/basic_info_tile.dart';
import 'package:bananatalk_app/pages/profile/edit_main/sections/language_section.dart';
import 'package:bananatalk_app/pages/profile/edit_main/sections/personal_section.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileEdit extends ConsumerStatefulWidget {
  final String userName;
  final String mbti;
  final String bloodType;
  final Location location;
  final String nativeLanguage;
  final String languageToLearn;
  final String gender;
  final String bio;
  final List<String> topics;
  final String? languageLevel;

  const ProfileEdit({
    super.key,
    required this.userName,
    required this.mbti,
    required this.bloodType,
    required this.location,
    required this.nativeLanguage,
    required this.languageToLearn,
    required this.gender,
    this.bio = '',
    this.topics = const [],
    this.languageLevel,
  });

  @override
  ConsumerState<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends ConsumerState<ProfileEdit> {
  Community? _cachedUser;

  late String selectedName;
  late String selectedMBTI;
  late String selectedBloodType;
  late String selectedNatLanguage;
  late String selectedLanguageToLearn;
  late String selectedGender;
  late String selectedAddress;
  late String selectedBio;
  late List<String> selectedTopics;
  late String? selectedLanguageLevel;

  @override
  void initState() {
    super.initState();
    const notSet = 'Not Set';
    selectedAddress = widget.location.formattedAddress.isEmpty
        ? notSet
        : widget.location.formattedAddress;
    selectedName = widget.userName.isEmpty ? notSet : widget.userName;
    selectedMBTI = widget.mbti.isEmpty ? notSet : widget.mbti;
    selectedBloodType = widget.bloodType.isEmpty ? notSet : widget.bloodType;
    selectedNatLanguage =
        widget.nativeLanguage.isEmpty ? notSet : widget.nativeLanguage;
    selectedLanguageToLearn =
        widget.languageToLearn.isEmpty ? notSet : widget.languageToLearn;
    selectedGender = widget.gender.isEmpty ? notSet : widget.gender;
    selectedBio = widget.bio.isEmpty ? notSet : widget.bio;
    selectedTopics = List.from(widget.topics);
    selectedLanguageLevel = widget.languageLevel;
  }

  // ─── Mutation callbacks passed to section widgets ─────────────────────────

  void _onNameGenderChanged(String name, String gender) =>
      setState(() {
        selectedName = name;
        selectedGender = gender;
      });

  void _onBioChanged(String bio) => setState(() => selectedBio = bio);

  void _onNativeLangChanged(String lang) =>
      setState(() => selectedNatLanguage = lang);

  void _onLearnLangChanged(String lang) =>
      setState(() => selectedLanguageToLearn = lang);

  void _onLanguageLevelChanged(String level) =>
      setState(() => selectedLanguageLevel = level);

  void _onMBTIChanged(String mbti) => setState(() => selectedMBTI = mbti);

  void _onBloodTypeChanged(String bt) =>
      setState(() => selectedBloodType = bt);

  void _onAddressChanged(String addr) =>
      setState(() => selectedAddress = addr);

  void _onTopicsChanged(List<String> topics) =>
      setState(() => selectedTopics = topics);

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final completion = calculateProfileCompletion(
      name: selectedName,
      gender: selectedGender,
      bio: selectedBio,
      nativeLanguage: selectedNatLanguage,
      languageToLearn: selectedLanguageToLearn,
      languageLevel: selectedLanguageLevel,
      mbti: selectedMBTI,
      address: selectedAddress,
      topics: selectedTopics,
    );

    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          l10n.editProfile,
          style: context.titleLarge.copyWith(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero header with avatar + animated completion bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _HeroHeader(
                  cachedUser: _cachedUser,
                  selectedName: selectedName,
                  completion: completion,
                  onUserLoaded: (user) {
                    if (mounted) setState(() => _cachedUser = user);
                  },
                ),
              ),

              // Basic info section (picture / name+gender / bio)
              BasicInfoSection(
                selectedName: selectedName,
                selectedGender: selectedGender,
                selectedBio: selectedBio,
                onNameGenderChanged: _onNameGenderChanged,
                onBioChanged: _onBioChanged,
              ),

              // Language section (native / learn / level picker)
              LanguageSection(
                selectedNativeLanguage: selectedNatLanguage,
                selectedLanguageToLearn: selectedLanguageToLearn,
                selectedLanguageLevel: selectedLanguageLevel,
                onNativeLanguageChanged: _onNativeLangChanged,
                onLanguageToLearnChanged: _onLearnLangChanged,
                onLanguageLevelChanged: _onLanguageLevelChanged,
              ),

              // Personal + interests sections (MBTI / blood / hometown / topics)
              PersonalSection(
                selectedMBTI: selectedMBTI,
                selectedBloodType: selectedBloodType,
                selectedAddress: selectedAddress,
                selectedTopics: selectedTopics,
                onMBTIChanged: _onMBTIChanged,
                onBloodTypeChanged: _onBloodTypeChanged,
                onAddressChanged: _onAddressChanged,
                onTopicsChanged: _onTopicsChanged,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero header widget ───────────────────────────────────────────────────────

class _HeroHeader extends ConsumerWidget {
  final Community? cachedUser;
  final String selectedName;
  final ProfileCompletion completion;
  final void Function(Community) onUserLoaded;

  const _HeroHeader({
    required this.cachedUser,
    required this.selectedName,
    required this.completion,
    required this.onUserLoaded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fresh = ref.watch(userProvider).valueOrNull;
    if (fresh != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onUserLoaded(fresh));
    }
    final imageUrl = (fresh ?? cachedUser)?.imageUrls.isNotEmpty == true
        ? (fresh ?? cachedUser)!.imageUrls.first
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: imageUrl != null
                      ? CachedImageWidget(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: _avatarPlaceholder(),
                        )
                      : _avatarPlaceholder(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.surfaceColor,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Completion info + animated progress bar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedName == 'Not Set'
                      ? AppLocalizations.of(context)!.editProfile
                      : selectedName,
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${completion.percent}% ',
                      style: context.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.profileCompleteProgress,
                      style: context.caption.copyWith(
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: completion.fraction),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
    );
  }
}
