import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  // Ganti dengan kredensial dari dashboard EmailJS kamu
  static const String _serviceId = 'service_vcelyrq';
  static const String _templateId = 'template_mxcb62l';
  static const String _publicKey = 'My_8Lm7u4RojBtMjW';

  /// Fungsi untuk mengirimi email otomatis ke Pembeli
  static Future<bool> sendEmail({
    required String toEmail,
    required String buyerName,
    required String productTitle,
    required String messageContent,
    String? scriptLink,
  }) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': toEmail,
            'buyer_name': buyerName,
            'product_title': productTitle,
            'message_content': messageContent,
            'script_link': scriptLink ?? '-',
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}