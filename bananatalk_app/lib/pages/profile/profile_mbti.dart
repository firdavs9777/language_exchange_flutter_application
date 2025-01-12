import 'package:flutter/material.dart';

class MBTIEdit extends StatefulWidget {
  const MBTIEdit({super.key});

  @override
  State<MBTIEdit> createState() => _MBTIEditState();
}

class _MBTIEditState extends State<MBTIEdit> {
  // List of MBTI types
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

  String? selectedMBTI; // To store selected MBTI

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
            // Displaying the MBTI options in a grid layout with 4 items per row
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
                        selectedMBTI = mbtiList[index]; // Update selected MBTI
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selectedMBTI == mbtiList[index]
                            ? Colors.blueAccent // Selected color
                            : Colors.grey[200], // Default color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedMBTI == mbtiList[index]
                              ? Colors.blue // Border color when selected
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
                              ? Colors.white // White text when selected
                              : Colors.black, // Black text when not selected
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Save Button
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  if (selectedMBTI != null) {
                    // Save the selected MBTI (For now, just show a message)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved: $selectedMBTI')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an MBTI')),
                    );
                  }
                },
                child: const Text('Save'),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 50), // Full-width button
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
