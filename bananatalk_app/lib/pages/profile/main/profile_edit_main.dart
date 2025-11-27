import 'package:bananatalk_app/pages/profile/personal_info/profile_blood_type.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_bio_edit.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_hometown.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_language_edit.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_mbti.dart';
import 'package:bananatalk_app/pages/profile/about/profile_info_set.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
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
            _buildEditCard(
              context: context,
              icon: Icons.person,
              iconColor: Colors.blue,
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
            const SizedBox(height: 8),
            _buildEditCard(
              context: context,
              icon: Icons.description,
              iconColor: Colors.purple,
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
            const SizedBox(height: 8),

            // Language Section
            _buildSectionHeader('Language Exchange', Icons.language),
            _buildEditCard(
              context: context,
              icon: Icons.translate,
              iconColor: Colors.blue,
              title: 'Native Language',
              subtitle: selectedNatLanguage,
                  onTap: () async {
                    final String updatedNatLang = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileLanguageEdit(
                              initialLanguage: selectedNatLanguage,
                              type: 'native',
                            ),
                          ),
                        ) ??
                        selectedNatLanguage;
                if (updatedNatLang != selectedNatLanguage) {
                    updateNatLang(updatedNatLang);
                }
              },
            ),
            const SizedBox(height: 8),
            _buildEditCard(
              context: context,
              icon: Icons.school,
              iconColor: Colors.orange,
              title: 'Language to Learn',
              subtitle: selectedLanguageToLearn,
                  onTap: () async {
                    final String updatedLangLearn = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileLanguageEdit(
                              initialLanguage: selectedLanguageToLearn,
                              type: 'learn',
                            ),
                          ),
                        ) ??
                        selectedLanguageToLearn;
                if (updatedLangLearn != selectedLanguageToLearn) {
                    updateLangLearn(updatedLangLearn);
                }
              },
            ),
            const SizedBox(height: 8),

            // Personal Information Section
            _buildSectionHeader('Personal Information', Icons.info_outline),
            _buildEditCard(
              context: context,
              icon: Icons.psychology,
              iconColor: Colors.purple,
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
            const SizedBox(height: 8),
            _buildEditCard(
              context: context,
              icon: Icons.bloodtype,
              iconColor: Colors.red,
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
            const SizedBox(height: 8),
            _buildEditCard(
              context: context,
              icon: Icons.location_on,
              iconColor: Colors.green,
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
            const SizedBox(height: 24),
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00BFA5).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF00BFA5)),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (value != null)
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitle == "Not Set"
                              ? Colors.grey[500]
                              : Colors.grey[700],
                          fontWeight: subtitle == "Not Set"
                              ? FontWeight.normal
                              : FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
