import 'package:flutter_test/flutter_test.dart';
import 'package:personal_expense_ai/services/receipt_parser_service.dart';

void main() {
  group('ReceiptParserService', () {
    final parser = ReceiptParserService();

    test('Trích xuất mô tả, tổng tiền và ngày hóa đơn', () {
      const rawText = '''
ABC MART
Ngay: 15/10/2026
Banh mi
Tong cong: 47.000 VND
''';

      final result = parser.parse(rawText);

      expect(result.description, 'ABC MART');
      expect(result.amount, 47000);
      expect(result.date, DateTime(2026, 10, 15));
      expect(result.rawText, rawText);
    });

    test('Trả về số tiền 0 khi không có số tiền hợp lệ', () {
      const rawText = '''
ABC MART
Cam on quy khach
''';

      final result = parser.parse(rawText);

      expect(result.amount, 0);
      expect(result.date, isNull);
    });

    test('Không chấp nhận ngày không hợp lệ', () {
      const rawText = '''
ABC MART
Ngay: 31/02/2026
Tong cong: 50.000 VND
''';

      final result = parser.parse(rawText);

      expect(result.date, isNull);
    });

    test('Nhận diện số tiền từ ảnh giao dịch ACB', () {
      const rawText = '''
09:44
Giao dịch thành công
1.050.000d
Thời gian giao dịch
Người nhận
Số thẻ/TK
Ngân hàng
Kết quả giao dịch
Mã giao dich
Tạo mẫu chuyển tiển để chuyển
nhanh hn vào lần sau
HCÀN SÂU
Giao dịch xác thực theo tiêu chuẩn quốc tế FIDO
1995 TEA
09:44 - 11/07/2026
CTY TNHH CONG NGHE
A PLUS
Khám phá hoàn tiển tại cửa hàng:
!!6
OTRẢ SAU Ví Trả Sau - Hoàn tiền 10%
Tối đa 10K/giao dịch • 07-31/07
Và 500,000+ cửa hàng khác:
9 Chuyển thêm >
Chia sè
3333588588
S Quản lý chi tiêu
137150032864 >
124, Lý Thường Kiệt, Phường7, Tuy Hòa, Phú Yên
TAP HÓA CÔ THU - 403 NGUYÊN H...
403, Nguyễn Huệ, Phường 7, Tuy Hòa, Phú Yên
& Chia tiền >
ACB
Tạo mẫu
Học tập v
''';

      final result = parser.parse(rawText);

      expect(result.amount, 1050000);
      expect(result.recipientName, 'CTY TNHH CONG NGHE A PLUS');
      expect(result.date, DateTime(2026, 7, 11));
      expect(result.recipientName, 'CTY TNHH CONG NGHE A PLUS');
    });
  });
}
