// lib/widgets/image_uploader.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploader extends StatelessWidget {
  final Function(XFile?) onImagePicked;

  const ImageUploader({super.key, required this.onImagePicked});

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    onImagePicked(image);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 50,
        child: Icon(Icons.camera_alt),
      ),
    );
  }
}