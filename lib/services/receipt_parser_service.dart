import '../models/receipt_data.dart';

class ReceiptParserService {
  /// Phân tích văn bản OCR thành dữ liệu hóa đơn.
  ReceiptData parse(String rawText) {
    return ReceiptData(
      description: _extractDescription(rawText),
      recipientName: _extractRecipientName(rawText),
      amount: _extractAmount(rawText),
      date: _extractDate(rawText),
      rawText: rawText,
    );
  }

  bool _isBankTransfer(String rawText) {
    final text = rawText.toLowerCase();

    const bankTransferKeywords = [
      'người nhận',
      'người thụ hưởng',
      'số tài khoản',
      'số thẻ',
      'mã giao dịch',
      'giao dịch thành công',
      'chuyển khoản',
      'transfer successful',
      'transaction id',
      'beneficiary',
    ];

    return bankTransferKeywords.any((keyword) => text.contains(keyword));
  }

  String? _extractRecipientName(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String normalize(String value) {
      return value
          .toLowerCase()
          .replaceAll('đ', 'd')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    bool isIgnored(String line) {
      final value = normalize(line);

      const ignoredPhrases = [
        'người nhận',
        'người thụ hưởng',
        'số thẻ',
        'số tài khoản',
        'ngân hàng',
        'kết quả giao dịch',
        'mã giao dịch',
        'thời gian giao dịch',
        'giao dịch thành công',
        'giao dịch xác thực',
        'tạo mẫu',
        'chuyển thêm',
        'chia sẻ',
        'chia tiền',
        'khám phá',
        'hoàn tiền',
        'tối đa',
        'cửa hàng',
        'học tập',
        'acb',
      ];

      return ignoredPhrases.any(value.contains) ||
          RegExp(r'^\d').hasMatch(line) ||
          RegExp(r'^[\d\s.,:/\-₫đ]+$').hasMatch(line);
    }

    bool isUppercaseNameLine(String line) {
      if (isIgnored(line)) return false;

      final letters = line.replaceAll(RegExp(r'[^a-zA-ZÀ-ỹĐđ]'), '');

      if (letters.length < 3) return false;

      return letters == letters.toUpperCase();
    }

    // Ưu tiên tìm tên doanh nghiệp theo cụm từ OCR:
    // "CTY TNHH CONG NGHE" + "A PLUS".
    for (var i = 0; i < lines.length; i++) {
      final normalized = normalize(lines[i]);

      if (normalized.startsWith('cty ') ||
          normalized.startsWith('cong ty ') ||
          normalized.startsWith('công ty ')) {
        if (!isUppercaseNameLine(lines[i])) continue;

        var name = lines[i];

        if (i + 1 < lines.length && isUppercaseNameLine(lines[i + 1])) {
          name = '$name ${lines[i + 1]}';
        }

        return name;
      }
    }

    // Dự phòng cho các giao dịch có tên người nhận viết hoa.
    final recipientIndex = lines.indexWhere(
      (line) => normalize(line).startsWith('nguoi nhan'),
    );

    if (recipientIndex >= 0) {
      for (var i = recipientIndex + 1; i < lines.length; i++) {
        if (isUppercaseNameLine(lines[i])) {
          var name = lines[i];

          if (i + 1 < lines.length && isUppercaseNameLine(lines[i + 1])) {
            name = '$name ${lines[i + 1]}';
          }

          return name;
        }
      }
    }

    return null;
  }

  String _extractDescription(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final ignoredLines = RegExp(
      r'^(h[oó]a\s*[đd]ơn|receipt|invoice|'
      r'cashier|thu\s*ng[aâ]n|'
      r'đ[cộ]ng\s*h[oó]a|'
      r'ng[aà]y|date|time|'
      r't[oổ]ng\s*c[oộ]ng|total|'
      r'th[aà]nh\s*ti[eề]n)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (ignoredLines.hasMatch(line)) continue;

      // Bỏ qua dòng chỉ chứa số, ngày hoặc ký hiệu.
      if (RegExp(
        r'^[\d\s.,:/\-₫đvnd]+$',
        caseSensitive: false,
      ).hasMatch(line)) {
        continue;
      }

      return line;
    }

    return 'Chi tiêu từ hóa đơn';
  }

  double _extractAmount(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final isBankTransfer = _isBankTransfer(rawText);

    if (isBankTransfer) {
      // Ưu tiên dòng có nhãn số tiền giao dịch.
      final transferAmountKeywords = RegExp(
        r's[oố]\s*ti[eề]n\s*(?:giao\s*d[iị]ch|chuy[eể]n\s*kho[aả]n)?'
        r'|amount|transaction\s*amount|transfer\s*amount',
        caseSensitive: false,
      );

      for (final line in lines) {
        if (!transferAmountKeywords.hasMatch(line)) continue;

        final amount = _findLastAmount(line);
        if (amount != null && amount > 0) {
          return amount;
        }
      }

      // OCR ngân hàng có thể đưa số tiền ra một dòng riêng,
      // ví dụ: 1.050.000d.
      final currencyAmountPattern = RegExp(
        r'(\d{1,3}(?:[., ]\d{3})+|\d{4,})\s*(?:đ|d|vnd|₫)(?!\w)',
        caseSensitive: false,
      );

      for (final line in lines) {
        final match = currencyAmountPattern.firstMatch(line);

        if (match == null) continue;

        final normalizedAmount = match
            .group(1)!
            .replaceAll(RegExp(r'[., ]'), '');

        final amount = double.tryParse(normalizedAmount);

        if (amount != null && amount > 0) {
          return amount;
        }
      }

      // Dự phòng: nhận diện số tiền có ký hiệu tiền tệ ở cuối,
      // ví dụ OCR đọc "1.050.000d" thay vì "1.050.000đ".
      final currencySuffix = RegExp(r'(?:đ|d|vnd|₫)\s*$', caseSensitive: false);

      for (final line in lines.reversed) {
        if (!currencySuffix.hasMatch(line)) continue;

        final normalizedLine = line.replaceFirst(currencySuffix, '');
        final amount = _findLastAmount(normalizedLine);

        if (amount != null && amount > 0) {
          return amount;
        }
      }

      // Không đoán số tiền từ số tài khoản hoặc mã giao dịch.
      return 0;
    }

    // Giữ logic nhận diện hóa đơn hiện tại.
    final totalKeywords = RegExp(
      r't[oổ]ng\s*c[oộ]ng|th[aà]nh\s*ti[eề]n|'
      r'c[oộ]ng\s*ti[eề]n|total\s*(?:due)?|grand\s*total|'
      r'amount\s*due|ph[aả]i\s*tr[aả]',
      caseSensitive: false,
    );

    for (final line in lines.reversed) {
      if (!totalKeywords.hasMatch(line)) continue;

      final amount = _findLastAmount(line);
      if (amount != null && amount > 0) {
        return amount;
      }
    }

    for (final line in lines.reversed) {
      final amount = _findLastAmount(line);
      if (amount != null && amount > 0) {
        return amount;
      }
    }

    return 0;
  }

  double? _findLastAmount(String line) {
    // Nhận diện số tiền dạng 47.000, 47,000, 47000
    // và số tiền có ký hiệu VND/đ.
    final matches = RegExp(
      r'(?<![\w/])(?:₫\s*)?(\d{1,3}(?:[., ]\d{3})+|\d{4,})(?:\s*(?:đ|vnd))?(?!\w)',
      caseSensitive: false,
    ).allMatches(line).toList();

    if (matches.isEmpty) return null;

    final value = matches.last.group(1);
    if (value == null) return null;

    final normalized = value.replaceAll(RegExp(r'[., ]'), '');
    return double.tryParse(normalized);
  }

  DateTime? _extractDate(String rawText) {
    // Định dạng yyyy-MM-dd hoặc yyyy/MM/dd.
    final yearFirst = RegExp(r'\b(20\d{2})[-/](\d{1,2})[-/](\d{1,2})\b');

    for (final match in yearFirst.allMatches(rawText)) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);

      final date = _validDate(year, month, day);
      if (date != null) return date;
    }

    // Định dạng dd/MM/yyyy, dd-MM-yyyy hoặc dd.MM.yyyy.
    final dayFirst = RegExp(r'\b(\d{1,2})[./-](\d{1,2})[./-](20\d{2})\b');

    for (final match in dayFirst.allMatches(rawText)) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);

      final date = _validDate(year, month, day);
      if (date != null) return date;
    }

    return null;
  }

  DateTime? _validDate(int year, int month, int day) {
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final date = DateTime(year, month, day);

    // DateTime tự điều chỉnh ngày không hợp lệ, nên cần kiểm tra lại.
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }

    return date;
  }
}
