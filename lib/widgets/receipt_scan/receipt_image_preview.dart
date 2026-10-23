import 'dart:io';

import 'package:flutter/material.dart';

class ReceiptImagePreview extends StatelessWidget {
  final String imagePath;

  const ReceiptImagePreview({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(imagePath),
        height: 240,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 160,
            child: Center(child: Text('Không thể hiển thị ảnh hóa đơn.')),
          );
        },
      ),
    );
  }
}
