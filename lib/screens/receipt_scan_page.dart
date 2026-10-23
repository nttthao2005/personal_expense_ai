import 'package:flutter/material.dart';

import '../services/image_picker_service.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser_service.dart';
import '../models/receipt_data.dart';
import '../models/transaction.dart';
import '../services/database_service.dart';
import '../widgets/receipt_scan/receipt_image_preview.dart';
import '../widgets/receipt_scan/receipt_ocr_result.dart';
import '../widgets/receipt_scan/receipt_confirmation_form.dart';

class ReceiptScanPage extends StatefulWidget {
  const ReceiptScanPage({super.key});

  @override
  State<ReceiptScanPage> createState() => _ReceiptScanPageState();
}

class _ReceiptScanPageState extends State<ReceiptScanPage> {
  final ImagePickerService _imagePickerService = ImagePickerService();
  final OcrService _ocrService = OcrService();
  final ReceiptParserService _receiptParserService = ReceiptParserService();
  final TextEditingController _recipientNameController =
      TextEditingController();
  String? _imagePath;
  String _recognizedText = '';
  bool _isLoading = false;
  bool _isSaving = false;
  ReceiptData? _receiptData;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  Future<void> _scanReceipt({required bool useCamera}) async {
    try {
      final imagePath = useCamera
          ? await _imagePickerService.captureFromCamera()
          : await _imagePickerService.pickFromGallery();

      if (!mounted || imagePath == null) return;

      setState(() {
        _imagePath = imagePath;
        _recognizedText = '';
        _receiptData = null;
        _descriptionController.clear();
        _recipientNameController.clear();
        _amountController.clear();
        _selectedDate = DateTime.now();
        _isLoading = true;
      });

      final text = await _ocrService.recognizeText(imagePath);
      debugPrint('===== OCR RAW TEXT =====\n$text');
      if (!mounted) return;

      final receiptData = text.trim().isEmpty
          ? null
          : _receiptParserService.parse(text);

      setState(() {
        _recognizedText = text;
        _receiptData = receiptData;
        _isLoading = false;

        if (receiptData != null) {
          _descriptionController.text = receiptData.description;
          _recipientNameController.text = receiptData.recipientName ?? '';

          if (receiptData.amount > 0) {
            _amountController.text = receiptData.amount.toStringAsFixed(0);
          }

          _selectedDate = receiptData.date ?? DateTime.now();
        }
      });

      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không nhận diện được văn bản trong ảnh.'),
          ),
        );
      } else if (receiptData == null ||
          receiptData.amount <= 0 ||
          receiptData.description.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa nhận diện đủ thông tin. Vui lòng kiểm tra và nhập lại mô tả, số tiền.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _recognizedText = '';
        _receiptData = null;
        _descriptionController.clear();
        _amountController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể nhận diện hóa đơn. Vui lòng thử lại bằng ảnh khác.',
          ),
        ),
      );
    }
  }

  Future<void> _saveReceipt() async {
    final description = _descriptionController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mô tả giao dịch.')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ.')),
      );
      return;
    }

    if (_receiptData == null || _recognizedText.trim().isEmpty) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final recipientName = _recipientNameController.text.trim();

      final transaction = ExpenseTransaction(
        title: description,
        recipientName: recipientName.isEmpty ? null : recipientName,
        amount: amount,
        type: TransactionType.expense,
        category: 'Hóa đơn',
        date: _selectedDate,
        note: 'Giao dịch được tạo từ hóa đơn OCR',
        rawOcrText: _recognizedText,
      );

      await DatabaseService.instance.insertTransaction(transaction);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu giao dịch từ hóa đơn thành công!'),
        ),
      );

      setState(() {
        _imagePath = null;
        _recognizedText = '';
        _receiptData = null;
        _descriptionController.clear();
        _amountController.clear();
        _selectedDate = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu giao dịch: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _recipientNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhận diện hóa đơn'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE3EAF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chọn ảnh có sẵn hoặc chụp hóa đơn để nhận diện thông tin giao dịch.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _scanReceipt(useCamera: true),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Chụp ảnh hóa đơn'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF173B67),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _scanReceipt(useCamera: false),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Chọn ảnh từ thư viện'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF173B67),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF173B67)),
                    ),
                  ),
                ],
              ),
            ),

            if (_imagePath != null && !_isLoading) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _imagePath = null;
                    _recognizedText = '';
                    _receiptData = null;
                    _descriptionController.clear();
                    _amountController.clear();
                    _selectedDate = DateTime.now();
                  });
                },

                icon: const Icon(Icons.refresh),
                label: const Text('Xóa hóa đơn hiện tại'),
              ),
            ],

            if (_imagePath != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Ảnh hóa đơn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF173B67),
                ),
              ),
              const SizedBox(height: 12),
              ReceiptImagePreview(imagePath: _imagePath!),
            ],

            if (_imagePath != null) ...[
              const SizedBox(height: 20),
              Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE3EAF2)),
                ),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: false,
                  leading: const Icon(
                    Icons.document_scanner_outlined,
                    color: Color(0xFF173B67),
                  ),
                  title: const Text(
                    'Kết quả nhận diện',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF173B67),
                    ),
                  ),
                  subtitle: Text(
                    _isLoading
                        ? 'Đang nhận diện văn bản...'
                        : _recognizedText.trim().isEmpty
                        ? 'Chưa có nội dung nhận diện'
                        : 'Nhấn để xem nội dung OCR',
                    style: const TextStyle(fontSize: 12),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: ReceiptOcrResult(
                        isLoading: _isLoading,
                        recognizedText: _recognizedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_receiptData != null) ...[
              ReceiptConfirmationForm(
                descriptionController: _descriptionController,
                amountController: _amountController,
                selectedDate: _selectedDate,
                recipientNameController: _recipientNameController,
                isSaving: _isSaving,
                onPickDate: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (pickedDate != null && mounted) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                onSave: _saveReceipt,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
