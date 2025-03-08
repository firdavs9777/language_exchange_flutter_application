import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileHometownEdit extends StatefulWidget {
  const ProfileHometownEdit({Key? key}) : super(key: key);

  @override
  State<ProfileHometownEdit> createState() => _ProfileHometownEditState();
}

class _ProfileHometownEditState extends State<ProfileHometownEdit> {
  List<Map<String, String>> countries = [];
  List<String> regions = [];
  String? selectedCountry;
  String? selectedCountryFlag;
  String? selectedRegion;
  bool isLoading = true;
  String? errorMessage;

  // Fetching countries list
  Future<void> getCountriesList() async {
    final url = Uri.parse('https://restcountries.com/v3.1/all');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          countries = data
              .map((item) => {
                    'name': item['name']['common'] as String,
                    'flag': item['flags']['png'] as String,
                    'code': item['cca2'] as String,
                  })
              .toList()
            ..sort((a, b) => a['name']!.compareTo(b['name']!));
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error when getting countries list: $error';
        isLoading = false;
      });
    }
  }

  // Fetching regions based on selected country
  Future<void> getRegions() async {
    if (selectedCountry == null) return;

    final encodedCountry = Uri.encodeQueryComponent(selectedCountry!);
    final url = Uri.parse(
        'https://countriesnow.space/api/v0.1/countries/cities/q?country=$encodedCountry');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          setState(() {
            regions = List<String>.from(data['data']);
            isLoading = false;
          });
        } else {
          throw Exception('Invalid data format');
        }
      } else {
        throw Exception('Failed to load regions');
      }
    } catch (error) {
      setState(() {
        errorMessage = 'Error when getting regions: $error';
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getCountriesList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hometown'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Your Hometown',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<Map<String, String>>(
                        value: selectedCountry != null
                            ? countries.firstWhere(
                                (country) => country['name'] == selectedCountry,
                                orElse: () => countries.first,
                              )
                            : null,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          labelText: 'Country',
                          labelStyle: const TextStyle(fontSize: 16),
                        ),
                        isExpanded: true,
                        items: countries.map((country) {
                          return DropdownMenuItem(
                            value: country,
                            child: Row(
                              children: [
                                Image.network(
                                  country['flag']!,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    country['name']!,
                                    overflow: TextOverflow.ellipsis,
                                    softWrap: false,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCountry = value!['name'];
                            selectedCountryFlag = value['flag'];
                            selectedRegion = null;
                            regions.clear();
                            isLoading = true;
                            getRegions();
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      if (regions.isNotEmpty)
                        DropdownButtonFormField<String>(
                          value: selectedRegion,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 12),
                            labelText: 'Region',
                            labelStyle: const TextStyle(fontSize: 16),
                          ),
                          isExpanded: true,
                          items: regions.map((region) {
                            return DropdownMenuItem(
                              value: region,
                              child: Text(region),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRegion = value;
                            });
                          },
                        ),
                      const SizedBox(height: 30),
                      Spacer(),
                      Center(
                        child: ElevatedButton(
                          onPressed:
                              selectedCountry != null && selectedRegion != null
                                  ? () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmation'),
                                          content: Text(
                                            'Your hometown is set to $selectedCountry, $selectedRegion.',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('OK'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 20),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
