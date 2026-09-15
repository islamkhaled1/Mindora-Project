import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/bx.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sawa/app_colors.dart';

class CustomImagePicker extends StatefulWidget {
  final String defaultImage;

  const CustomImagePicker({super.key, required this.defaultImage});

  @override
  State<CustomImagePicker> createState() => _CustomImagePickerState();
}

class _CustomImagePickerState extends State<CustomImagePicker> {
  File? selectedImage;

  final ImagePicker picker = ImagePicker();

  Future<void> pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context, ImageSource.camera);
              },
            ),

            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context, ImageSource.gallery);
              },
            ),
          ],
        );
      },
    );

    if (source == null) return;

    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            width: 200.w,
            height: 200.w,
            child: selectedImage != null
                ? Image.file(selectedImage!, fit: BoxFit.cover)
                : Image.asset(widget.defaultImage, fit: BoxFit.cover),
          ),
        ),

        Positioned(
          bottom: 0,
          right: 20,
          child: GestureDetector(
            onTap: pickImage,
            child: Container(
              width: 38.w,
              height: 38.h,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Iconify(
                  Bx.bxs_camera,
                  size: 30,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
