import 'package:flutter/material.dart';

class ReceiptOcrResult extends StatelessWidget {
  final bool isLoading;
  final String recognizedText;

  const ReceiptOcrResult({
    super.key,
    required this.isLoading,
    required this.recognizedText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Kết quả nhận diện',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (!isLoading && recognizedText.trim().isNotEmpty)
              const Icon(Icons.check_circle, color: Colors.green, size: 22),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text(
                  'Đang nhận diện nội dung hóa đơn...',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              recognizedText.isEmpty
                  ? 'Không có văn bản để hiển thị.'
                  : recognizedText,
            ),
          ),
      ],
    );
  }
}
