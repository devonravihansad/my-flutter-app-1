import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // QR scanner
import 'package:wedding_app/features/auth/screens/login_screen.dart';
import 'package:wedding_app/features/dashboard/widgets/qr_scan_screen.dart';
import 'package:wedding_app/features/dashboard/widgets/photo_grid.dart'; // your existing photo_grid (expects List<String>)
import 'package:wedding_app/features/dashboard/widgets/full_photo_viewer.dart'; // your swipe viewer

class GuestDashboardScreen extends StatefulWidget {
  const GuestDashboardScreen({super.key});

  @override
  State<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends State<GuestDashboardScreen> {
  String? selectedAlbumId;
  Map<String, dynamic>? albumData;
  bool loadingAlbum = false;
  bool albumLoaded = false;

  // ----- Core Album Loader -----
  Future<void> loadAlbumById(String albumId) async {
    setState(() {
      loadingAlbum = true;
      albumLoaded = false;
    });

    final doc = await FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .get();

    if (!doc.exists) {
      showSnack('Invalid album');
      setState(() => loadingAlbum = false);
      return;
    }

    // Save and show album
    setState(() {
      selectedAlbumId = albumId;
      albumData = doc.data()!;
      loadingAlbum = false;
      albumLoaded = true;
    });
  }

  // ----- QR Scan -----
  void scanQrCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScanScreen(
          onCodeScanned: (code) async {
            Navigator.pop(context);
            if (code.isEmpty) {
              showSnack('Invalid QR code');
            } else {
              await handleSharedLink(code);
            }
          },
        ),
      ),
    );
  }

  // ----- Passkey Input -----
  void enterPasskey() async {
    final keyController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enter Passkey'),
        content: TextField(
          controller: keyController,
          decoration: const InputDecoration(hintText: 'Enter passkey here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, keyController.text),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await handleSharedLink(result);
    }
  }

  Future<void> handleSharedLink(String code) async {
    final snap = await FirebaseFirestore.instance
        .collection('shared_links')
        .where('passkey', isEqualTo: code)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      showSnack('Invalid Code');
      return;
    }

    final data = snap.docs.first.data();

    // Expiry check before album fetch
    final expiryTs = data['expiresAt'];
    if (expiryTs is Timestamp && expiryTs.toDate().isBefore(DateTime.now())) {
      showSnack('Expired album link');
      return;
    }

    final isPrivate = data['isPrivate'] ?? false;

    // Block screenshots if restricted
    if (isPrivate) {
      await disableScreenshots();
    }

    await loadAlbumById(data['albumId']);
  }

  // ----- UI -----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guest Album View')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: scanQrCode,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR'),
              ),
              ElevatedButton.icon(
                onPressed: enterPasskey,
                icon: const Icon(Icons.key),
                label: const Text('Enter Passkey'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: loadingAlbum
                ? const Center(child: CircularProgressIndicator())
                : !albumLoaded
                ? const Center(child: Text('Scan QR or enter passkey'))
                : StreamBuilder<List<String>>(
                    stream: photoUrlsStream(selectedAlbumId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final photos = snapshot.data ?? [];
                      if (photos.isEmpty) {
                        return const Center(
                          child: Text('No photos in this album'),
                        );
                      }
                      return PhotoGrid(
                        photos: photos,
                        // onPhotoTap: (index) => openFullViewer(photos, index),
                        // allowDownload: albumData?['allowDownload'] ?? true,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ----- Reusable Helpers -----
  Stream<List<String>> photoUrlsStream(String albumId) {
    return FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('photos')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d['url'] as String).toList());
  }

  void openFullViewer(List<String> photos, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullPhotoViewer(imageUrls: photos, initialIndex: index),
      ),
    );
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> disableScreenshots() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: [],
      );
      // Also use flutter_windowmanager if needed for Android
    } catch (_) {}
  }
}
