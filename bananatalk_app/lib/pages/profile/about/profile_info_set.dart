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
  final List<String?> _genders = ['Male', 'Female'];
  @override
  void initState() {
    super.initState();
    _controllerName = TextEditingController(text: widget.userName);
    _selectedGender = widget.gender.isNotEmpty ? widget.gender : null;
  }

  @override
  void dispose() {
    _controllerName.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile Name')),
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
                await ref
                    .read(authServiceProvider)
                    .updateUserName(userName: _controllerName.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Saved: ${_controllerName.text}')),
                );
                // Navigator.of(context).pop(_controllerName.text);
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
