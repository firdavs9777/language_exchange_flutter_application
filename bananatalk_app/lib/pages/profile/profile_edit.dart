import 'package:bananatalk_app/pages/profile/profile_blood_type.dart';
import 'package:bananatalk_app/pages/profile/profile_hometown.dart';
import 'package:bananatalk_app/pages/profile/profile_mbti.dart';
import 'package:flutter/material.dart';

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Personal Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )),
            ),
            Card(
              color: Colors.white,
              elevation: 1,
              margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.all(16), // Add padding inside the card
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
                  'ENTP',
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
                          builder: (context) => const MBTIEdit()));
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
                contentPadding:
                    const EdgeInsets.all(16), // Add padding inside the card
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blueAccent, // Background color for the avatar
                  child: const Icon(
                    Icons
                        .bloodtype, // Change this to something related to MBTI, e.g., icon for ENTP
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
                  'Type A',
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
                          builder: (context) => const PersonBloodType()));
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
                contentPadding:
                    const EdgeInsets.all(16), // Add padding inside the card
                leading: CircleAvatar(
                  backgroundColor:
                      Colors.blueAccent, // Background color for the avatar
                  child: const Icon(
                    Icons
                        .home_filled, // Change this to something related to MBTI, e.g., icon for ENTP
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
                  'Earth',
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
                          builder: (context) => const ProfileHometownEdit()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
