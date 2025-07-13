import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class WhisperService {
  static Future<String> transcribe(String audioFilePath) async {
    try {
      print("📤 Sending file to Whisper backend...");
      final file = File(audioFilePath!);
      final size = await file.length();
      print("📏 File size: $size bytes");
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.20:5000/transcribe'), // your backend
      );

      request.files.add(await http.MultipartFile.fromPath('file', audioFilePath));

      var response = await request.send();
      final res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        print("✅ Transcript received: ${res.body}");
        return res.body;
      } else {
        print("❌ Error from server: ${res.statusCode} - ${res.body}");
        return 'Error: ${res.statusCode} - ${res.body}';
      }
    } catch (e) {
      print("❌ Exception: $e");
      return 'Exception: $e';
    }
  }
}
