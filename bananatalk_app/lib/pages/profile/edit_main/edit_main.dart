import 'package:bananatalk_app/pages/profile/edit/blood_type_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/bio_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/hometown_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/language_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/mbti_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/picture_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/topics_edit.dart';
import 'package:bananatalk_app/pages/profile/edit/name_gender_edit.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/widgets/cached_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bananatalk_app/utils/app_page_route.dart';

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
  late String selectedNatLanguage;
  late String selectedBloodType;
  late String selectedNativeLanguage;
  late String selectedLanguageToLearn;
  late String selectedGender;
  late String selectedAddress;
  late String selectedBio;
  late List<String> selectedTopics;
  late String? selectedLanguageLevel;

  @override
  void initState() {
    super.initState();
    final notSet = "Not Set";
    selectedAddress = widget.location.formattedAddress.isEmpty
        ? notSet
        : widget.location.formattedAddress;
    selectedName = widget.userName.isEmpty ? notSet : widget.userName;
    selectedMBTI = widget.mbti.isEmpty ? notSet : widget.mbti;
    selectedBloodType = widget.bloodType.isEmpty ? notSet : widget.bloodType;
    selectedNatLanguage = widget.nativeLanguage.isEmpty
        ? notSet
        : widget.nativeLanguage;
    selectedLanguageToLearn = widget.languageToLearn.isEmpty
        ? notSet
        : widget.languageToLearn;
    selectedGender = widget.gender.isEmpty ? notSet : widget.gender;
    selectedBio = widget.bio.isEmpty ? notSet : widget.bio;
    selectedTopics = List.from(widget.topics);
    selectedLanguageLevel = widget.languageLevel;
  }

  void updateMBTI(String newMBTI) => setState(() => selectedMBTI = newMBTI);
  void updateNatLang(String newNatLang) =>
      setState(() => selectedNatLanguage = newNatLang);
  void updateLangLearn(String newLangLearn) =>
      setState(() => selectedLanguageToLearn = newLangLearn);
  void updateBloodType(String newBloodType) =>
      setState(() => selectedBloodType = newBloodType);
  void updateUserAddress(String newAddress) =>
      setState(() => selectedAddress = newAddress);
  void updateBio(String newBio) => setState(() => selectedBio = newBio);
  void updateTopics(List<String> newTopics) =>
      setState(() => selectedTopics = newTopics);

  void updateUserName(String newUserName, String selectedGenderVal) {
    setState(() {
      selectedName = newUserName;
      selectedGender = selectedGenderVal;
    });
  }

  String _getTopicsDisplayText(AppLocalizations l10n) {
    if (selectedTopics.isEmpty) return l10n.notSet;
    final topicNames = selectedTopics
        .map((id) {
          final topic = Topic.defaultTopics.firstWhere(
            (t) => t.id == id,
            orElse: () => Topic(id: id, name: id, icon: '', category: ''),
          );
          return topic.name;
        })
        .take(3)
        .toList();

    if (selectedTopics.length > 3) {
      return '${topicNames.join(', ')} +${selectedTopics.length - 3} ${l10n.more}';
    }
    return topicNames.join(', ');
  }

  /// Calculates profile completion percentage based on filled fields
  double _calculateCompletion() {
    int filled = 0;
    const total = 9;
    if (selectedName != "Not Set") filled++;
    if (selectedGender != "Not Set") filled++;
    if (selectedBio != "Not Set") filled++;
    if (selectedNatLanguage != "Not Set") filled++;
    if (selectedLanguageToLearn != "Not Set") filled++;
    if (selectedLanguageLevel != null) filled++;
    if (selectedMBTI != "Not Set") filled++;
    if (selectedAddress != "Not Set") filled++;
    if (selectedTopics.isNotEmpty) filled++;
    return filled / total;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final completion = _calculateCompletion();

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
              // Hero header with avatar + completion
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _buildHeroHeader(l10n, completion),
              ),

              // Basic Info
              _buildSectionHeader(
                l10n.basicInformation,
                Icons.person_rounded,
                AppColors.primary,
              ),
              _buildSectionContainer([
                Consumer(
                  builder: (context, ref, child) {
                    final fresh = ref.watch(userProvider).valueOrNull;
                    if (fresh != null) _cachedUser = fresh;
                    final user = _cachedUser;
                    if (user == null) return const SizedBox.shrink();
                    return _buildModernEditTile(
                      icon: Icons.photo_camera_rounded,
                      iconColor: AppColors.primary,
                      title: l10n.profilePicture,
                      subtitle: user.imageUrls.isNotEmpty
                          ? l10n.tapToChange
                          : l10n.noPictureSet,
                      isFirst: true,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) =>
                                ProfilePictureEdit(user: user),
                          ),
                        );
                        ref.invalidate(userProvider);
                      },
                    );
                  },
                ),
                _buildDivider(),
                _buildModernEditTile(
                  icon: Icons.badge_rounded,
                  iconColor: AppColors.info,
                  title: l10n.nameAndGender,
                  subtitle: selectedName == "Not Set" ? null : selectedName,
                  trailingChip: selectedGender != "Not Set"
                      ? selectedGender
                      : null,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (context) => ProfileInfoSet(
                          userName: selectedName,
                          gender: selectedGender,
                        ),
                      ),
                    );
                    if (result != null) {
                      updateUserName(result['userName'], result['gender']);
                    }
                  },
                ),
                _buildDivider(),
                _buildModernEditTile(
                  icon: Icons.description_rounded,
                  iconColor: AppColors.accent,
                  title: l10n.bio,
                  subtitle: selectedBio == "Not Set"
                      ? null
                      : (selectedBio.length > 60
                            ? '${selectedBio.substring(0, 60)}...'
                            : selectedBio),
                  isLast: true,
                  onTap: () async {
                    final String updatedBio =
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ProfileBioEdit(
                              currentBio: selectedBio == "Not Set"
                                  ? ''
                                  : selectedBio,
                            ),
                          ),
                        ) ??
                        selectedBio;
                    if (updatedBio != selectedBio) updateBio(updatedBio);
                  },
                ),
              ]),

              // Language Section
              _buildSectionHeader(
                l10n.languageExchange,
                Icons.language_rounded,
                AppColors.info,
              ),
              _buildSectionContainer([
                _buildModernEditTile(
                  icon: Icons.translate_rounded,
                  iconColor: AppColors.info,
                  title: l10n.nativeLanguage,
                  subtitle: selectedNatLanguage == "Not Set"
                      ? null
                      : selectedNatLanguage,
                  isFirst: true,
                  onTap: () async {
                    final String updatedNatLang =
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ProfileLanguageEdit(
                              initialLanguage: selectedNatLanguage,
                              type: 'native',
                              otherLanguage: selectedLanguageToLearn,
                            ),
                          ),
                        ) ??
                        selectedNatLanguage;
                    if (updatedNatLang != selectedNatLanguage) {
                      updateNatLang(updatedNatLang);
                    }
                  },
                ),
                _buildDivider(),
                _buildModernEditTile(
                  icon: Icons.school_rounded,
                  iconColor: AppColors.warning,
                  title: l10n.languageToLearn,
                  subtitle: selectedLanguageToLearn == "Not Set"
                      ? null
                      : selectedLanguageToLearn,
                  onTap: () async {
                    final String updatedLangLearn =
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ProfileLanguageEdit(
                              initialLanguage: selectedLanguageToLearn,
                              type: 'learn',
                              otherLanguage: selectedNatLanguage,
                            ),
                          ),
                        ) ??
                        selectedLanguageToLearn;
                    if (updatedLangLearn != selectedLanguageToLearn) {
                      updateLangLearn(updatedLangLearn);
                    }
                  },
                ),
                _buildDivider(),
                _buildModernEditTile(
                  icon: Icons.bar_chart_rounded,
                  iconColor: const Color(0xFF7C4DFF),
                  title: l10n.languageLevel,
                  subtitle: selectedLanguageLevel,
                  trailingChip: selectedLanguageLevel,
                  isLast: true,
                  onTap: _showLanguageLevelPicker,
                ),
              ]),

              // Personal Information
              _buildSectionHeader(
                l10n.personalInformation,
                Icons.info_rounded,
                AppColors.accent,
              ),
              _buildSectionContainer([
                _buildModernEditTile(
                  icon: Icons.psychology_rounded,
                  iconColor: AppColors.accent,
                  title: l10n.mbti,
                  subtitle: selectedMBTI == "Not Set" ? null : selectedMBTI,
                  trailingChip: selectedMBTI != "Not Set" ? selectedMBTI : null,
                  isFirst: true,
                  onTap: () async {
                    final String updatedMbtiType =
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) =>
                                MBTIEdit(currentMBTI: selectedMBTI),
                          ),
                        ) ??
                        selectedMBTI;
                    if (updatedMbtiType != selectedMBTI) {
                      updateMBTI(updatedMbtiType);
                    }
                  },
                ),
                _buildDivider(),
                _buildModernEditTile(
                  icon: Icons.bloodtype_rounded,
                  iconColor: AppColors.error,
                  title: l10n.bloodType,
                  subtitle: selectedBloodType == "Not Set"
                      ? null
                      : selectedBloodType,
                  trailingChip: selectedBloodType != "Not Set"
                      ? selectedBloodType
                      : null,
                  onTap: () async {
                    final String updatedBloodType =
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => PersonBloodType(
                              currentSelectedBloodType: selectedBloodType,
                            ),
                          ),
                        ) ??
                        selectedBloodType;
                    if (updatedBloodType != selectedBloodType) {
                      updateBloodType(updatedBloodType);
                    }
                  },
                ),
                _buildDivider(),
                _buildModernEditTile(
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.success,
                  title: l10n.hometown,
                  subtitle: selectedAddress == "Not Set"
                      ? null
                      : selectedAddress,
                  isLast: true,
                  onTap: () async {
                    final String newAddress =
                        await Navigator.push(
                          context,
                          AppPageRoute(
                            builder: (context) => ProfileHometownEdit(
                              currentAddress: selectedAddress,
                            ),
                          ),
                        ) ??
                        selectedAddress;
                    if (newAddress != selectedAddress) {
                      updateUserAddress(newAddress);
                    }
                  },
                ),
              ]),

              // Interests
              _buildSectionHeader(
                l10n.interests,
                Icons.favorite_rounded,
                const Color(0xFFE91E63),
              ),
              _buildSectionContainer([
                _buildModernEditTile(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFE91E63),
                  title: l10n.topicsOfInterest,
                  subtitle: selectedTopics.isEmpty
                      ? null
                      : _getTopicsDisplayText(l10n),
                  trailingChip: selectedTopics.isNotEmpty
                      ? '${selectedTopics.length}'
                      : null,
                  isFirst: true,
                  isLast: true,
                  onTap: () async {
                    final List<String>? result = await Navigator.push(
                      context,
                      AppPageRoute(
                        builder: (context) => ProfileTopicsEdit(
                          initialTopics: selectedTopics,
                          isStandalone: true,
                        ),
                      ),
                    );
                    if (result != null) updateTopics(result);
                  },
                ),
              ]),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ========== HERO HEADER ==========
  Widget _buildHeroHeader(AppLocalizations l10n, double completion) {
    final percent = (completion * 100).round();

    return Consumer(
      builder: (context, ref, _) {
        final fresh = ref.watch(userProvider).valueOrNull;
        if (fresh != null) _cachedUser = fresh;
        final imageUrl = _cachedUser?.imageUrls.isNotEmpty == true
            ? _cachedUser!.imageUrls.first
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
              // Completion info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedName == "Not Set"
                          ? l10n.editProfile
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
                          '$percent% ',
                          style: context.titleSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          l10n.profileCompleteProgress,
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
                        tween: Tween(begin: 0, end: completion),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.15,
                          ),
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
      },
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      child: Icon(Icons.person_rounded, size: 36, color: AppColors.primary),
    );
  }

  // ========== SECTION HEADER ==========
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: context.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ========== SECTION CONTAINER (groups tiles into a single card) ==========
  Widget _buildSectionContainer(List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.06))
            : null,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.dividerColor.withValues(alpha: 0.5),
      ),
    );
  }

  // ========== MODERN EDIT TILE ==========
  Widget _buildModernEditTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    String? trailingChip,
    bool isFirst = false,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isEmpty = subtitle == null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final radius = BorderRadius.only(
      topLeft: Radius.circular(isFirst ? 20 : 0),
      topRight: Radius.circular(isFirst ? 20 : 0),
      bottomLeft: Radius.circular(isLast ? 20 : 0),
      bottomRight: Radius.circular(isLast ? 20 : 0),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.bodySmall.copyWith(
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isEmpty ? l10n.notSet : subtitle,
                      style: isEmpty
                          ? context.bodyMedium.copyWith(
                              color: context.textMuted,
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                            )
                          : context.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Trailing chip (e.g., "INTJ", "B+", "5")
              if (trailingChip != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    trailingChip,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
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

  // ========== LANGUAGE LEVEL PICKER ==========
  String _getLanguageLevelDescription(String level, AppLocalizations l10n) {
    switch (level) {
      case 'A1':
        return l10n.levelBeginner;
      case 'A2':
        return l10n.levelElementary;
      case 'B1':
        return l10n.levelIntermediate;
      case 'B2':
        return l10n.levelUpperIntermediate;
      case 'C1':
        return l10n.levelAdvanced;
      case 'C2':
        return l10n.levelProficient;
      default:
        return '';
    }
  }

  void _showLanguageLevelPicker() {
    final l10n = AppLocalizations.of(context)!;
    final levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
    const accent = Color(0xFF7C4DFF);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectYourLevel,
                        style: context.titleLarge.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.howWellDoYouSpeak(
                          selectedLanguageToLearn != "Not Set"
                              ? selectedLanguageToLearn
                              : l10n.theLanguage,
                        ),
                        style: context.bodySmall.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: levels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final level = levels[i];
                      final isSelected = selectedLanguageLevel == level;
                      final desc = _getLanguageLevelDescription(level, l10n);
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onLanguageLevelSelected(ctx, level),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accent.withValues(alpha: 0.1)
                                  : context.containerColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? accent : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? const LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [accent, Color(0xFF9C7CFF)],
                                          )
                                        : null,
                                    color: isSelected
                                        ? null
                                        : context.containerHighColor,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: accent.withValues(
                                                alpha: 0.3,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    level,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: isSelected
                                          ? Colors.white
                                          : context.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    desc,
                                    style: context.titleSmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: accent,
                                    size: 24,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLanguageLevelSelected(
    BuildContext sheetCtx,
    String level,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    Navigator.pop(sheetCtx);
    setState(() => selectedLanguageLevel = level);
    try {
      await ref
          .read(authServiceProvider)
          .updateUserLanguageLevel(languageLevel: level);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.languageLevelSetTo(level))),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToUpdate}: $e'),
            backgroundColor: colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
