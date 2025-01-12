import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileHometownEdit extends StatefulWidget {
  const ProfileHometownEdit({super.key});

  @override
  State<ProfileHometownEdit> createState() => _ProfileHometownEditState();
}

class _ProfileHometownEditState extends State<ProfileHometownEdit> {
  List<Map<String, String>> countries = [];
  List<String> regions = [];
  String? selectedCountry;
  String? selectedCountryFlag;
  bool isLoading = true;
  String? errorMessage;

  // Fetching countries list
  Future<void> getCountriesList() async {
    final url = Uri.parse('https://restcountries.com/v3.1/all'); // API URL
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
            ..sort((a, b) =>
                a['name']!.compareTo(b['name']!)); // Sort alphabetically
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
  Future<void> getRegions(String countryName) async {
    final url =
        Uri.parse('https://country-regions.p.rapidapi.com/country-regions');
    const headers = {
      'Content-Type': 'application/json',
      'x-rapidapi-host': 'country-regions.p.rapidapi.com',
      'x-rapidapi-key':
          '240fa8cf42msh227fd27272c6a4ep134022jsn23d109a5c9db', // Replace with your API key
    };

    final body = json.encode({'countryName': countryName});

    try {
      final response = await http.post(url, headers: headers, body: body);
      print(response);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          regions = List<String>.from(data[
              'regions']); // Assuming the response contains a 'regions' array
          isLoading = false;
        });
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
        title: const Text('Profile Hometown'),
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButton<Map<String, String>>(
                        value: selectedCountry != null
                            ? countries.firstWhere(
                                (country) => country['name'] == selectedCountry,
                              )
                            : null,
                        hint: const Text('Select a country'),
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
                            // Fetch regions after country selection
                            // getRegions(value['name']!);
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (selectedCountry != null)
                        Row(
                          children: [
                            if (selectedCountryFlag != null)
                              Image.network(
                                selectedCountryFlag!,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              'Selected Country: $selectedCountry',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      // if (regions.isNotEmpty)
                      //   Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       const Text(
                      //         'Select a Region:',
                      //         style: TextStyle(
                      //           fontSize: 16,
                      //           fontWeight: FontWeight.bold,
                      //         ),
                      //       ),
                      //       const SizedBox(height: 8),
                      //       DropdownButton<String>(
                      //         hint: const Text('Select a region'),
                      //         isExpanded: true,
                      //         items: regions.map((region) {
                      //           return DropdownMenuItem(
                      //             value: region,
                      //             child: Text(region),
                      //           );
                      //         }).toList(),
                      //         onChanged: (value) {
                      //           // You can handle region selection here
                      //           print('Selected region: $value');
                      //         },
                      //       ),
                      //     ],
                      //   ),
                    ],
                  ),
      ),
    );
  }
}
