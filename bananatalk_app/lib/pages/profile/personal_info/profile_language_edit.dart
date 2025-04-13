import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileLanguageEdit extends ConsumerStatefulWidget {
  final String
      currentMBTI; // Use 'final' since it's being passed in but not changed here
  const ProfileLanguageEdit({super.key, required this.currentMBTI});

  @override
  _ProfileLanguageEditState createState() => _ProfileLanguageEditState();
}

class _ProfileLanguageEditState extends ConsumerState<ProfileLanguageEdit> {
  final List<String> mbtiList = [
    'INTJ',
    'INTP',
    'ENTJ',
    'ENTP',
    'INFJ',
    'INFP',
    'ENFJ',
    'ENFP',
    'ISTJ',
    'ISFJ',
    'ESTJ',
    'ESFJ',
    'ISTP',
    'ISFP',
    'ESTP',
    'ESFP',
  ];

  late String selectedMBTI; // Declare state variable to track selected MBTI

  @override
  void initState() {
    super.initState();
    selectedMBTI = widget.currentMBTI.isEmpty
        ? ''
        : widget.currentMBTI; // Initialize with the passed-in value
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your MBTI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: mbtiList.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMBTI = mbtiList[index];
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedMBTI == mbtiList[index]
                            ? Colors.blueAccent
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedMBTI == mbtiList[index]
                              ? Colors.blue
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        mbtiList[index],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: selectedMBTI == mbtiList[index]
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(authServiceProvider)
                      .updateUserMbti(mbti: selectedMBTI);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Saved: $selectedMBTI')),
                  );
                  Navigator.of(context).pop(selectedMBTI);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
