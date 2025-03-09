import 'package:bananatalk_app/pages/profile/personal_info/profile_blood_type.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_hometown.dart';
import 'package:bananatalk_app/pages/profile/personal_info/profile_mbti.dart';
import 'package:bananatalk_app/pages/profile/about/profile_info_set.dart';
import 'package:bananatalk_app/providers/provider_models/community_model.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod package

class ProfileEdit extends ConsumerStatefulWidget {
  final String userName;
  final String mbti;
  final String bloodType;
  final Location location;
  final String nativeLanguage;
  final String languageToLearn;
  final String gender;
  const ProfileEdit(
      {super.key,
      required this.userName,
      required this.mbti,
      required this.bloodType,
      required this.location,
      required this.nativeLanguage,
      required this.languageToLearn,
      required this.gender});

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
  @override
  void initState() {
    super.initState();
    selectedName = widget.userName.isEmpty ? "Not Set" : widget.userName;
    selectedMBTI = widget.mbti.isEmpty ? "Not Set" : widget.mbti;
    selectedBloodType = widget.bloodType.isEmpty ? 'Not Set' : widget.bloodType;
    selectedNatLanguage =
        widget.nativeLanguage.isEmpty ? "Not Set" : widget.nativeLanguage;
    selectedLanguageToLearn =
        widget.languageToLearn.isEmpty ? "Not Set" : widget.languageToLearn;
    selectedGender = widget.gender.isEmpty ? "Not Set" : widget.gender;
  }

  void updateMBTI(String newMBTI) {
    setState(() {
      selectedMBTI = newMBTI;
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

  @override
  Widget build(BuildContext context) {
    // Access the provider data using ref.watch() within the ConsumerStatefulWidget

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // This is the back button icon
          onPressed: () {
            ref.refresh(userProvider);
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'About Me',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      child: const Icon(
                        Icons
                            .person, // Change this to something related to MBTI, e.g., icon for ENTP
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      'Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      selectedName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 22,
                      color:
                          Colors.grey[600], // Subtle gray color for the arrow
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ProfileInfoSet(
                                  userName: selectedName,
                                  gender: selectedGender)));
                      updateUserName(result['userName'], result['gender']);

                      // if (result != null && result is Map<String, String>) {
                      //   final String updatedUserName =
                      //       result['userName'] ?? selectedName;
                      //   final String updatedGender =
                      //       result['gender'] ?? selectedGender;
                      //   updateUserName(updatedUserName, updatedGender);
                      //
                      //   setState(() {
                      //     selectedName =
                      //         result['userName'] ?? selectedName.toString();
                      //   });
                      //   print(selectedName);
                      // Update the userProvider with the new data
                    }),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Language',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    child: const Icon(
                      Icons
                          .language, // Change this to something related to MBTI, e.g., icon for ENTP
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'First Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    selectedNatLanguage,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 22,
                    color: Colors.grey[600], // Subtle gray color for the arrow
                  ),
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
                    updateMBTI(updatedMbtiType);
                  },
                ),
              ),
              Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    child: const Icon(
                      Icons
                          .library_books_outlined, // Change this to something related to MBTI, e.g., icon for ENTP
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'Language to learn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    selectedLanguageToLearn,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 22,
                    color: Colors.grey[600], // Subtle gray color for the arrow
                  ),
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
                    updateMBTI(updatedMbtiType);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Card(
                color: Colors.white,
                elevation: 1,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    child: const Icon(
                      Icons
                          .coffee, // Change this to something related to MBTI, e.g., icon for ENTP
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'My MBTI',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    selectedMBTI,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 22,
                    color: Colors.grey[600], // Subtle gray color for the arrow
                  ),
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
                    updateMBTI(updatedMbtiType);
                  },
                ),
              ),
              Card(
                elevation: 1,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(
                      Icons.bloodtype,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'My Blood Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    selectedBloodType,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 22,
                    color: Colors.grey[600], // Subtle gray color for the arrow
                  ),
                  onTap: () async {
                    final String updatedBloodType = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonBloodType(
                                currentSelectedBloodType: selectedBloodType),
                          ),
                        ) ??
                        selectedBloodType;
                    updateBloodType(updatedBloodType);
                  },
                ),
              ),
              Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: const Icon(
                      Icons.home_filled,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    'My Hometown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    widget.location
                        .formattedAddress, // Replace with actual hometown data from the provider if needed
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 22,
                    color: Colors.grey[600], // Subtle gray color for the arrow
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileHometownEdit(),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Interests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
