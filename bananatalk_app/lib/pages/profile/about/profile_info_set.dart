import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileInfoSet extends ConsumerStatefulWidget {
  final String userName;
  final String gender;
  const ProfileInfoSet({super.key, required this.userName, this.gender = ''});

  @override
  ConsumerState<ProfileInfoSet> createState() => _ProfileInfoSetState();
}

class _ProfileInfoSetState extends ConsumerState<ProfileInfoSet> {
  late TextEditingController _controllerName;
  late String? _selectedGender;
  final List<String?> _genders = ['Male', 'Female', 'Other'];

  // Convert backend lowercase to display format
  String? _convertGenderToDisplay(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    final lowerGender = gender.toLowerCase();
    if (lowerGender == 'male') return 'Male';
    if (lowerGender == 'female') return 'Female';
    if (lowerGender == 'other') return 'Other';
    return null;
  }

  // Convert display format back to backend lowercase
  String? _convertGenderToBackend(String? gender) {
    if (gender == null || gender.isEmpty) return null;
    return gender.toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _controllerName = TextEditingController(text: widget.userName);
    _selectedGender = _convertGenderToDisplay(widget.gender);
  }

  @override
  void dispose() {
    _controllerName.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Profile Name',
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back), // This is the back button icon
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            TextField(
              controller: _controllerName,
              decoration: const InputDecoration(
                labelText: 'Enter your name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                isDense: true,
                menuMaxHeight: 400,
                value: _selectedGender,
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue!;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.grey),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  labelText: 'Gender(Required)',
                  hintText: 'Select your gender',
                  prefixIcon: Icon(Icons.person),
                ),
                items: _genders.map<DropdownMenuItem<String>>((String? gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(
                      gender ?? 'Select gender',
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Convert display gender back to backend format (lowercase)
                final backendGender = _convertGenderToBackend(_selectedGender);
                await ref.read(authServiceProvider).updateUserName(
                    userName: _controllerName.text, gender: backendGender);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Saved: ${_controllerName.text} ${_selectedGender ?? "N/A"}'),
                    duration: const Duration(seconds: 3), // Show for 3 seconds
                  ),
                );

                Navigator.pop(context, {
                  'userName': _controllerName.text,
                  'gender': backendGender ?? ''
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
