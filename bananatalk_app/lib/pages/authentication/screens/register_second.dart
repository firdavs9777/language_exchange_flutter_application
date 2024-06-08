import 'dart:convert';
import 'dart:io';

import 'package:bananatalk_app/pages/authentication/screens/register.dart';
import 'package:bananatalk_app/pages/menu_tab/TabBarMenu.dart';
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
  late TextEditingController _bioController;
  String? _nativelanguage;
  String? _language_to_learn;
  // String? _imageUrl;

  late TextEditingController _birthDate;
  late TextEditingController _image;

// List of available languages
  List<String> _languages = [];

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
    final XFile? pickedImage =
        await _picker.pickImage(source: ImageSource.gallery);
    print(pickedImage);
    setState(() {
      _imageFile = pickedImage;
    });
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
                  SizedBox(width: 10),
                  // IconButton(
                  //   onPressed: _pickImage,
                  //   icon: Icon(Icons.photo),
                  //   tooltip: 'Pick Image',
                  // ),
                  if (_imageFile != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
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
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (ctx) => TabsScreen()));
                            },
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
