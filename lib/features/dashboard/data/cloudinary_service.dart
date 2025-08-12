import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';

class CloudinaryService {
  static const cloudName = 'dyx5bwi1l';
  static const apiKey = '456672697754794';
  static const apiSecret = 'YUJR9ZBGA8jZNfAlUK6G5KPFmhw';

  static Future<String> uploadImageToCloudinary(File imageFile) async {
    final uploadUrl = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final request = http.MultipartRequest('POST', uploadUrl)
      ..fields['upload_preset'] = 'ml_default'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: basename(imageFile.path),
        ),
      );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['secure_url'];
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
