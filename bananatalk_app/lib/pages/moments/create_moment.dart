import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:bananatalk_app/providers/provider_root/moments_providers.dart';

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

  void _updateButtonState() {
    isButtonEnabled.value = titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty;
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
                onPressed: isEnabled
                    ? () async {
                        final moment = await ref
                            .read(momentsServiceProvider)
                            .createMoments(
                              title: titleController.text,
                              description: descriptionController.text,
                            );

                        // // print('Momentss');
                        // // print(moment);
                        await ref
                            .read(momentsServiceProvider)
                            .uploadMomentPhotos(
                              moment.id,
                              _selectedImages,
                            );

                        ref.refresh(momentsProvider);
                        Navigator.of(context).pop();
                      }
                    : null,
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
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ),
            if (_selectedImages.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: Text(
                        'Images will appear here, please press upload icon at the bottom')),
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
                icon: const Icon(
                  Icons.upload_file,
                  size: 30,
                ),
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
                onPressed: () {
                  // Implement location functionality
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
