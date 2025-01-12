import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class CreateMoment extends ConsumerStatefulWidget {
  const CreateMoment({Key? key}) : super(key: key);

  @override
  _CreateMomentState createState() => _CreateMomentState();
}

class _CreateMomentState extends ConsumerState<CreateMoment> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final ValueNotifier<bool> isButtonEnabled = ValueNotifier(false);
  List<File> _selectedImages = [];
  Position? _currentPosition;
  String? _formattedAddress;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    titleController.addListener(_updateButtonState);
    descriptionController.addListener(_updateButtonState);
  }

  @override
  void dispose() {
    titleController.removeListener(_updateButtonState);
    descriptionController.removeListener(_updateButtonState);
    titleController.dispose();
    descriptionController.dispose();
    isButtonEnabled.dispose();
    super.dispose();
  }

  void _updateButtonState() {
    isButtonEnabled.value = titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _selectedImages
            .addAll(pickedFiles.map((pickedFile) => File(pickedFile.path)));
      });
      _updateButtonState();
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true; // Show loading indicator while requesting permission
    });

    var status = await Permission.location.request();
    print(status);
    if (status.isGranted) {
      await _getCurrentLocation();
    } else if (status.isDenied) {
      _showPermissionDeniedDialog();
    } else if (status.isPermanentlyDenied) {
// Permission permanently denied, show a dialog to guide to settings
      _showPermissionPermanentlyDeniedDialog();
    }

    setState(() {
      _isLoading = false; // Hide loading indicator after permission request
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
          _currentPosition!.latitude, _currentPosition!.longitude);
      Placemark place = placemarks[0];
      setState(() {
        _formattedAddress =
            "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}";
      });
    } catch (e) {
      print("Error getting location: $e");
      _showErrorDialog("Could not fetch location.");
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Denied'),
          content:
              const Text('Please allow location access to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
              'Location permission has been permanently denied. Please enable it in the app settings.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                openAppSettings(); // Open app settings
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createMoment() async {
    if (_isLoading) return; // Prevent multiple submissions
    setState(() {
      _isLoading = true;
    });

    final moment = await ref.read(momentsServiceProvider).createMoments(
          title: titleController.text,
          description: descriptionController.text,
        );

    await ref
        .read(momentsServiceProvider)
        .uploadMomentPhotos(moment.id, _selectedImages);

    ref.refresh(momentsProvider);
    Navigator.of(context).pop();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Moment'),
        actions: <Widget>[
          ValueListenableBuilder<bool>(
            valueListenable: isButtonEnabled,
            builder: (context, isEnabled, child) {
              return TextButton(
                onPressed: isEnabled && !_isLoading ? _createMoment : null,
                child: Text(
                  'Post',
                  style: TextStyle(
                    color: isEnabled
                        ? Colors.lightBlue
                        : Colors.lightBlue
                            .withOpacity(0.5), // Conditional color
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: TextField(
                maxLines: 10,
                controller: descriptionController,
                decoration:
                    const InputDecoration(labelText: 'What\'s on your mind?'),
              ),
            ),
            if (_selectedImages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: Text(
                        'Images will appear here, please press the upload icon at the bottom')),
              ),
            if (_selectedImages.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
              ),
            if (_currentPosition != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Location: Lat: ${_currentPosition!.latitude}, Lng: ${_currentPosition!.longitude}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            if (_formattedAddress != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Address: $_formattedAddress',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                color: Colors.red,
                icon: const Icon(Icons.upload_file, size: 30),
                onPressed: _pickImage,
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: () {
                  // Implement camera functionality
                },
              ),
              IconButton(
                icon: const Icon(Icons.video_call),
                onPressed: () {
                  // Implement video functionality
                },
              ),
              IconButton(
                  icon: const Icon(Icons.location_on),
                  onPressed: _requestLocationPermission),
            ],
          ),
        ),
      ),
    );
  }
}
