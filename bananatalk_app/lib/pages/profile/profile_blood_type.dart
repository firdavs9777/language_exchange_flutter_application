import 'package:flutter/material.dart';

class PersonBloodType extends StatefulWidget {
  const PersonBloodType({super.key});

  @override
  State<PersonBloodType> createState() => _PersonBloodTypeState();
}

class _PersonBloodTypeState extends State<PersonBloodType> {
  // List of blood types
  final List<String> bloodTypes = [
    'Type A',
    'Type B',
    'Type AB',
    'Type O',
    'Type A-',
    'Type B-',
    'Type AB-',
    'Type O-'
  ];

  // Variable to store the selected blood type
  String? selectedBloodType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Blood Type'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Displaying the blood type options in a grid layout with 4 items per row
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 items per row
                  crossAxisSpacing: 10, // Horizontal space between items
                  mainAxisSpacing: 10, // Vertical space between items
                ),
                itemCount: bloodTypes.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedBloodType =
                            bloodTypes[index]; // Update selected blood type
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selectedBloodType == bloodTypes[index]
                            ? Colors.blueAccent // Selected color
                            : Colors.grey[200], // Default color
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selectedBloodType == bloodTypes[index]
                              ? Colors.blue // Border color when selected
                              : Colors.grey,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bloodTypes[index],
                        style: TextStyle(
                          fontSize: 14, // Smaller text size
                          fontWeight: FontWeight.bold,
                          color: selectedBloodType == bloodTypes[index]
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
                  if (selectedBloodType != null) {
                    // Save the selected blood type (For now, just show a message)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved: $selectedBloodType')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please select a blood type')),
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
