import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/pages/authentication/screens/register.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
import 'package:bananatalk_app/providers/provider_root/auth_providers.dart';
import 'package:bananatalk_app/providers/provider_models//users_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class RegisterTwo extends ConsumerStatefulWidget {
  const RegisterTwo(
      {super.key,
      required this.name,
      required this.email,
      required this.password});
  final String name;
  final String email;
  final String password;

  @override
  ConsumerState<RegisterTwo> createState() => _RegisterTwoState();
}

class _RegisterTwoState extends ConsumerState<RegisterTwo> {
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];
  late TextEditingController _bioController;
  String? _nativelanguage;
  String? _language_to_learn;

  // String? _imageUrl;

  late TextEditingController _birthDate;
  late TextEditingController _image;

// List of available languages
  List<String> _languages = [];
  List<File> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
    // _language_to_learn = TextEditingController();
    _birthDate = TextEditingController();
    _image = TextEditingController();
    // ref.watch(authStatesProvider);
    fetchLanguages(); // Fetch languages when the widget initializes
  }

  @override
  void dispose() {
    _bioController.dispose();
    // _native_language.dispose();
    // _language_to_learn.dispose();
    _birthDate.dispose();
    _image.dispose();

    super.dispose();
  }

  void fetchLanguages() async {
    final response =
        await http.get(Uri.parse('http://localhost:5002/api/v1/languages'));

    if (response.statusCode == 200) {
      // If the call to the server was successful, parse the JSON
      List<dynamic> data = json.decode(response.body)['data'];
      setState(() {
        _languages = data.map<String>((lang) => lang['name']).toList();
      });
    } else {
      // If that call was not successful, throw an error.
      throw Exception('Failed to load languages');
    }
  }

  XFile? _imageFile;

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _selectedImages
            .addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)));
      });
    }
  }

  void submit() async {
    // Split birth date to extract year, month, and day
    List<String> dateParts = _birthDate.text.split('.');
    String year = dateParts[0];
    String month = dateParts[1];
    String day = dateParts[2];
    // Create a User object with the provided data
    User user = User(
      name: widget.name,
      password: widget.password,
      email: widget.email,
      bio: _bioController.text,
      gender: _selectedGender.toString(),
      image: _imageFile.toString(),
      // Note: Ensure this is the correct way to represent the image path
      birth_day: day,
      birth_month: month,
      birth_year: year,
      native_language: _nativelanguage.toString(),
      language_to_learn: _language_to_learn.toString(),
    );

    // Register the user using the authServiceProvider
    final user_response = await ref.read(authServiceProvider).register(user);
    print(user_response.id);

    await ref
        .read(authServiceProvider)
        .uploadUserPhoto(user_response.id, _selectedImages);

    ref.refresh(authServiceProvider);
    // Registration successful, navigate to the TabsScreen
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (ctx) => const TabsScreen(),
    ));

    // Show a success message if needed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registration Successful!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Form(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 10, left: 20, right: 20),
                    width: 200,
                    child: Image.asset(
                      'assets/images/logo_no_background.png',
                      height: 120,
                      width: 180,
                    ),
                  ),
                  Text(
                    'Complete your registration',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                      fontSize: 22,
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SingleChildScrollView(
                    child: TextFormField(
                      maxLines: 2,
                      controller: _bioController,
                      decoration: InputDecoration(
                          filled: true,
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.grey),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          labelText: 'Bio(Required)',
                          hintText: 'For example) I love watching movies',
                          prefixIcon: Icon(Icons.interests)),
                      onChanged: (value) {
                        // Update name variable
                      },
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 400,
                      value: _nativelanguage,
                      onChanged: (newValue) {
                        setState(() {
                          _nativelanguage = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelText: 'Native Language(Required)',
                        hintText: 'Select your native language',
                        prefixIcon: Icon(Icons.chat),
                      ),
                      items: _languages
                          .map<DropdownMenuItem<String>>((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(
                            language,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      isDense: true,
                      menuMaxHeight: 400,
                      value: _language_to_learn,
                      onChanged: (newValue) {
                        setState(() {
                          _language_to_learn = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        labelText: 'Language to learn(Required)',
                        hintText: 'Korean',
                        prefixIcon: Icon(Icons.language),
                      ),
                      items: _languages
                          .map<DropdownMenuItem<String>>((String language) {
                        return DropdownMenuItem<String>(
                          value: language,
                          child: Text(
                            language,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 10),
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
                          _selectedGender = newValue;
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
                      items: _genders
                          .map<DropdownMenuItem<String>>((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(
                            gender,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: _birthDate,
                    decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.grey),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        hintText: 'Birth Date',
                        prefixIcon: Icon(Icons.date_range)),
                    readOnly: true,
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        String formattedDate =
                            DateFormat('yyyy.MM.dd').format(pickedDate);
                        setState(() {
                          _birthDate.text = formattedDate;
                        });
                      }
                    },
                    onChanged: (value) {
                      // Update name variable
                    },
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  TextFormField(
                    controller: _image,
                    decoration: InputDecoration(
                      filled: true,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hintText: 'Profile Image',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    readOnly: true,
                    onTap: _pickImage,
                  ),
                  if (_selectedImages.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: Text(
                              'Images will appear here, please press profile image')),
                    ),
                  if (_selectedImages.isNotEmpty)
                    GridView.builder(
                      shrinkWrap:
                          true, // Allow the GridView to shrink and expand
                      physics:
                          NeverScrollableScrollPhysics(), // Disable scrolling of GridView to use the parent scroll
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 1,
                      ),
                      itemCount: _selectedImages.length + 1,
                      itemBuilder: (context, index) {
                        if (index < _selectedImages.length) {
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          );
                        } else {
                          return GestureDetector(
                            onTap: _pickImage,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.add, size: 50),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => Register()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepOrange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                            child: Text(
                              'Previous',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                            ),
                            child: Text(
                              'Complete',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
