import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultiPhotoBatchUploader {
  final String cloudName;
  final String uploadPreset;
  final String albumId;
  final BuildContext context;
  final int batchSize;
  // How many uploads at once

  MultiPhotoBatchUploader({
    required this.cloudName,
    required this.uploadPreset,
    required this.albumId,
    required this.context,
    this.batchSize = 5,
    // Default: 5 parallel uploads
  });

  final ImagePicker _picker = ImagePicker();

  Future<void> pickAndUploadMultiple() async {
    try {
      final pickedFiles = await _picker.pickMultiImage();
      if (pickedFiles.isEmpty) {
        _showSnackBar("No images selected");
        return;
      }

      int total = pickedFiles.length;
      int completed = 0;

      _showSnackBar("Starting upload of $total photos...");

      // Process in batches
      for (var i = 0; i < pickedFiles.length; i += batchSize) {
        final batch = pickedFiles.skip(i).take(batchSize).toList();

        await Future.wait(
          batch.map((file) async {
            await _uploadSingleFile(file);
            completed++;
            _showSnackBar("Uploaded $completed of $total");
          }),
        );
      }

      _showSnackBar("All $total photos uploaded successfully");
    } catch (e) {
      _showSnackBar("Upload failed: $e");
    }
  }

  Future<void> _uploadSingleFile(XFile file) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset;

    if (kIsWeb) {
      Uint8List fileBytes = await file.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: file.name),
      );
    } else {
      File localFile = File(file.path);
      request.files.add(
        await http.MultipartFile.fromPath('file', localFile.path),
      );
    }

    final response = await request.send();
    final resBody = await http.Response.fromStream(response);

    if (resBody.statusCode == 200) {
      final data = json.decode(resBody.body);
      if (data['secure_url'] != null) {
        await FirebaseFirestore.instance
            .collection('albums')
            .doc(albumId)
            .collection('photos')
            .add({'url': data['secure_url'], 'uploadedAt': Timestamp.now()});
      }
    } else {
      throw Exception("Upload failed: ${resBody.statusCode}");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}
