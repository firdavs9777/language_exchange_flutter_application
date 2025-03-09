import 'dart:io';
import 'package:flutter/material.dart';
import 'package:bananatalk_app/providers/provider_models/moments_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class EditMomentScreen extends ConsumerStatefulWidget {
  final Moments moment;
  const EditMomentScreen({Key? key, required this.moment}) : super(key: key);
  @override
  _EditMomentScreenState createState() => _EditMomentScreenState();
}

class _EditMomentScreenState extends ConsumerState<EditMomentScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  final List<File> _selectedImages = [];

  late List<String> imageUrls;
  @override
  void initState() {
    print(widget.moment.imageUrls);
    super.initState();
    titleController = TextEditingController(text: widget.moment.title);
    descriptionController =
        TextEditingController(text: widget.moment.description);
    imageUrls = List<String>.from(
        widget.moment.imageUrls); // Clone the list to allow editing
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
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
    }
  }

  void _saveChanges() {
    Navigator.pop(
      context,
      Moments(
        id: widget.moment.id,
        title: titleController.text,
        user: widget.moment.user,
        description: descriptionController.text,
        images: widget.moment.images,
        imageUrls: widget.moment.imageUrls,
        likedUsers: widget.moment.likedUsers,
        comments: widget.moment.comments,
        likeCount: widget.moment.likeCount,
        commentCount: widget.moment.commentCount,
        createdAt: widget.moment.createdAt,
      ),
    );
  }

  void _removeImage(String url) {
    setState(() {
      imageUrls.remove(url);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Moment'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ),
            if (widget.moment.imageUrls.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                    child: Text(
                        'Images will appear here, please press the upload icon to upload more images')),
              ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 1,
                ),
                itemCount: imageUrls.length + _selectedImages.length + 1,
                itemBuilder: (context, index) {
                  if (index < imageUrls.length) {
                    final url = imageUrls[index];
                    return Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.network(
                            url,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(url),
                            child: Container(
                              padding: const EdgeInsets.all(4.0),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (index <
                      imageUrls.length + _selectedImages.length) {
                    final file = _selectedImages[index - imageUrls.length];
                    return Stack(children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.file(
                          file,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImages.remove(file);
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ]);
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
            // Add an image uploader if needed
          ],
        ),
      ),
    );
  }
}
