import 'dart:convert';

import 'package:http/http.dart' as http;

class AiAnalysisService {
  // Địa chỉ backend FastAPI trên Android Emulator.
  static const String baseUrl = 'http://10.0.2.2:8000';
  Future<String> analyzeExpenses({
    required String period,
    required double totalIncome,
    required double totalExpense,
    required double balance,
    required List<Map<String, dynamic>> categories,
  }) async {
    final uri = Uri.parse('$baseUrl/analyze');

    final response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'period': period,
            'total_income': totalIncome,
            'total_expense': totalExpense,
            'balance': balance,
            'categories': categories,
          }),
        )
        .timeout(const Duration(seconds: 60));

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && data['status'] == 'success') {
      final analysis = data['analysis'];

      if (analysis is String && analysis.trim().isNotEmpty) {
        return analysis;
      }

      throw Exception('Backend không trả về nội dung phân tích.');
    }

    final detail = data['detail'];
    throw Exception(
      detail is String
          ? detail
          : 'Không thể phân tích chi tiêu (HTTP ${response.statusCode}).',
    );
  }

  Future<bool> checkBackendConnection() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      return data['status'] == 'healthy' && data['gemini_configured'] == true;
    } catch (_) {
      return false;
    }
  }
}
