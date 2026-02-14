import 'package:bananatalk_app/pages/profile/personal_info/profile_blood_type.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_bio_edit.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_hometown.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_language_edit.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_mbti.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_picture_edit.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_topics_edit.dart';
import 'package:bananatalk_app/pages/profile/about/profile_info_set.dart';
import 'package:bananatalk_app/models/community/topic_model.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';
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
  });

  @override
  ConsumerState<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends ConsumerState<ProfileEdit> {
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

  @override
  void initState() {
    super.initState();
    selectedAddress = widget.location.formattedAddress.isEmpty
        ? "Not Set"
        : widget.location.formattedAddress;
    selectedName = widget.userName.isEmpty ? "Not Set" : widget.userName;
    selectedMBTI = widget.mbti.isEmpty ? "Not Set" : widget.mbti;
    selectedBloodType = widget.bloodType.isEmpty ? 'Not Set' : widget.bloodType;
    selectedNatLanguage =
        widget.nativeLanguage.isEmpty ? "Not Set" : widget.nativeLanguage;
    selectedLanguageToLearn =
        widget.languageToLearn.isEmpty ? "Not Set" : widget.languageToLearn;
    selectedGender = widget.gender.isEmpty ? "Not Set" : widget.gender;
    selectedBio = widget.bio.isEmpty ? "Not Set" : widget.bio;
    selectedTopics = List.from(widget.topics);
  }

  void updateMBTI(String newMBTI) {
    setState(() {
      selectedMBTI = newMBTI;
    });
  }

  void updateNatLang(String newNatLang) {
    setState(() {
      selectedNatLanguage = newNatLang;
    });
  }

  void updateLangLearn(String newLangLearn) {
    setState(() {
      selectedLanguageToLearn = newLangLearn;
    });
  }

  void updateUserName(String newUserName, String selectedGenderVal) {
    setState(() {
      selectedName = newUserName;
      selectedGender = selectedGenderVal;
    });
  }

  void updateBloodType(String newBloodType) {
    setState(() {
      selectedBloodType = newBloodType;
    });
  }

  void updateUserAddress(String newAddress) {
    setState(() {
      selectedAddress = newAddress;
    });
  }

  void updateBio(String newBio) {
    setState(() {
      selectedBio = newBio;
    });
  }

  void updateTopics(List<String> newTopics) {
    setState(() {
      selectedTopics = newTopics;
    });
  }

  String _getTopicsDisplayText() {
    if (selectedTopics.isEmpty) return 'Not Set';

    // Get topic names from IDs
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
      return '${topicNames.join(', ')} +${selectedTopics.length - 3} more';
    }
    return topicNames.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          'Edit Profile',
          style: context.titleLarge,
        ),
        elevation: 0,
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.refresh(userProvider);
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information', Icons.person),
            Consumer(
              builder: (context, ref, child) {
                final userAsync = ref.watch(userProvider);
                return userAsync.when(
                  data: (user) => _buildEditCard(
                    context: context,
                    icon: Icons.photo_camera,
                    iconColor: const Color(0xFF00BFA5),
                    title: 'Profile Picture',
                    subtitle: user.imageUrls.isNotEmpty
                        ? 'Tap to change'
                        : 'No picture set',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePictureEdit(user: user),
                        ),
                      );
                      // Refresh user data after returning
                      ref.refresh(userProvider);
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                );
              },
            ),
            Spacing.gapSM,
            _buildEditCard(
              context: context,
              icon: Icons.person,
              iconColor: AppColors.info,
              title: 'Name & Gender',
              subtitle: selectedName,
              value: selectedGender != "Not Set" ? selectedGender : null,
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
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
            Spacing.gapSM,
            _buildEditCard(
              context: context,
              icon: Icons.description,
              iconColor: AppColors.accent,
              title: 'Bio',
              subtitle: selectedBio == "Not Set" 
                  ? "Not Set" 
                  : (selectedBio.length > 50 
                      ? '${selectedBio.substring(0, 50)}...' 
                      : selectedBio),
              onTap: () async {
                final String updatedBio = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileBioEdit(
                          currentBio: selectedBio == "Not Set" ? '' : selectedBio,
                        ),
                      ),
                    ) ??
                    selectedBio;
                if (updatedBio != selectedBio) {
                  updateBio(updatedBio);
                }
              },
            ),
            Spacing.gapSM,

            // Language Section
            _buildSectionHeader('Language Exchange', Icons.language),
            _buildEditCard(
              context: context,
              icon: Icons.translate,
              iconColor: AppColors.info,
              title: 'Native Language',
              subtitle: selectedNatLanguage,
                  onTap: () async {
                    final String updatedNatLang = await Navigator.push(
                          context,
                          MaterialPageRoute(
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
            Spacing.gapSM,
            _buildEditCard(
              context: context,
              icon: Icons.school,
              iconColor: AppColors.warning,
              title: 'Language to Learn',
              subtitle: selectedLanguageToLearn,
                  onTap: () async {
                    final String updatedLangLearn = await Navigator.push(
                          context,
                          MaterialPageRoute(
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
            Spacing.gapSM,

            // Personal Information Section
            _buildSectionHeader('Personal Information', Icons.info_outline),
            _buildEditCard(
              context: context,
              icon: Icons.psychology,
              iconColor: AppColors.accent,
              title: 'MBTI',
              subtitle: selectedMBTI,
                  onTap: () async {
                    final String updatedMbtiType = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MBTIEdit(
                              currentMBTI: selectedMBTI,
                            ),
                          ),
                        ) ??
                        selectedMBTI;
                if (updatedMbtiType != selectedMBTI) {
                    updateMBTI(updatedMbtiType);
                }
              },
            ),
            Spacing.gapSM,
            _buildEditCard(
              context: context,
              icon: Icons.bloodtype,
              iconColor: AppColors.error,
              title: 'Blood Type',
              subtitle: selectedBloodType,
                  onTap: () async {
                    final String updatedBloodType = await Navigator.push(
                          context,
                          MaterialPageRoute(
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
            Spacing.gapSM,
            _buildEditCard(
              context: context,
              icon: Icons.location_on,
              iconColor: AppColors.success,
              title: 'Hometown',
              subtitle: selectedAddress,
                  onTap: () async {
                    final String newAddress = await Navigator.push(
                          context,
                          MaterialPageRoute(
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
            Spacing.gapSM,

            // Interests Section
            _buildSectionHeader('Interests', Icons.interests),
            _buildEditCard(
              context: context,
              icon: Icons.favorite,
              iconColor: const Color(0xFFE91E63),
              title: 'Topics of Interest',
              subtitle: selectedTopics.isEmpty
                  ? 'Not Set'
                  : _getTopicsDisplayText(),
              onTap: () async {
                final List<String>? result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileTopicsEdit(
                      initialTopics: selectedTopics,
                      isStandalone: true,
                    ),
                  ),
                );
                if (result != null) {
                  updateTopics(result);
                }
              },
            ),
            Spacing.gapXXL,
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Container(
            padding: Spacing.paddingSM,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: AppRadius.borderSM,
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          Spacing.hGapMD,
          Builder(
            builder: (context) => Text(
              title,
              style: context.titleLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: AppRadius.borderLG,
        boxShadow: AppShadows.md,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.borderLG,
          child: Padding(
            padding: Spacing.paddingLG,
            child: Row(
              children: [
                Container(
                  padding: Spacing.paddingMD,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: AppRadius.borderMD,
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                Spacing.hGapLG,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.titleMedium,
                      ),
                      Spacing.gapXS,
                      if (value != null)
                        Text(
                          value,
                          style: context.labelSmall,
                        ),
                      Text(
                        subtitle,
                        style: subtitle == "Not Set"
                            ? context.bodySmall.copyWith(color: context.textMuted)
                            : context.bodySmall.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: context.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
