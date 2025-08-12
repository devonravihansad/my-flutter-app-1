import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wedding_app/features/auth/screens/login_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wedding_app/features/dashboard/data/shared_link_repository.dart';
import '../widgets/photo_grid.dart'; // your existing photo_grid (expects List<String>)
import 'package:wedding_app/features/dashboard/widgets/full_photo_viewer.dart'; // your swipe viewer
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientDashboardScreen extends StatefulWidget {
  final String clientId;

  const ClientDashboardScreen({super.key, required this.clientId});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  final SharedLinkRepository _linkRepo = SharedLinkRepository();

  List<QueryDocumentSnapshot> albums = [];
  String? selectedAlbumId;

  @override
  void initState() {
    super.initState();
    loadAlbums(widget.clientId);
  }

  /// Load all albums for this client
  Future<void> loadAlbums(String clientId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('albums')
        .where('clientId', isEqualTo: clientId)
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      albums = snapshot.docs;
      if (albums.isNotEmpty) {
        selectedAlbumId = albums.first.id; // default to first album
      }
    });
  }

  /// Stream of photo URLs for currently selected album
  Stream<List<String>> photoUrlsStream(String albumId) {
    return FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('photos')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc['url'] as String).toList());
  }

  /// Create and show QR code for album sharing
  Future<void> _createShareLink(Duration? duration) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Not authenticated')));
      return;
    }

    if (selectedAlbumId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an album first')),
      );
      return;
    }

    final link = await _linkRepo.createShareLink(
      albumId: selectedAlbumId!,
      creatorId: user.uid,
      validFor: duration,
    );

    final qrContent = link.passkey;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Share Album',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                QrImageView(
                  data: qrContent,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Passkey: ${link.passkey}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Expires: ${link.expiresAt?.toLocal().toString() ?? "Never"}',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show share duration options
  void _showShareOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Share for 1 hour'),
              onTap: () {
                Navigator.pop(context);
                _createShareLink(const Duration(hours: 1));
              },
            ),
            ListTile(
              title: const Text('Share for 24 hours'),
              onTap: () {
                Navigator.pop(context);
                _createShareLink(const Duration(hours: 24));
              },
            ),
            ListTile(
              title: const Text('Share forever'),
              onTap: () {
                Navigator.pop(context);
                _createShareLink(null);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Client Dashboard')),
      body: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              // final prefs = await SharedPreferences.getInstance();
              // await prefs.remove('rememberMe'); // remove remember preference
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
              );
            },
          ),
          // Album selector
          if (albums.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: DropdownButton<String>(
                hint: const Text('Select Album'),
                value: selectedAlbumId,
                isExpanded: true,
                items: albums.map((doc) {
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(doc['title']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedAlbumId = value;
                  });
                },
              ),
            ),

          // Share button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showShareOptions,
                  icon: const Icon(Icons.share),
                  label: const Text('Create Guest Link'),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Create QR or passkey to share with guests'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Photo grid for selected album
          if (selectedAlbumId != null)
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: photoUrlsStream(selectedAlbumId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final photos = snapshot.data ?? [];
                  if (photos.isEmpty) {
                    return const Center(child: Text('No photos yet'));
                  }
                  return PhotoGrid(photos: photos);
                },
              ),
            )
          else
            const Expanded(
              child: Center(child: Text('Select an album to view photos')),
            ),
        ],
      ),
    );
  }
}

/*
class ClientDashboardScreen extends StatefulWidget {
  final String clientId;
  const ClientDashboardScreen({super.key, required this.clientId});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  List<QueryDocumentSnapshot> albums = [];
  String? selectedAlbumId;
  bool loadingAlbums = true;

  @override
  void initState() {
    super.initState();
    loadAlbums(widget.clientId);
  }

  Future<void> loadAlbums(String clientId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('albums')
            .where('clientId', isEqualTo: clientId)
            .orderBy('createdAt', descending: true)
            .get();

    setState(() {
      albums = snapshot.docs;
      loadingAlbums = false;
    });
  }

  Stream<List<String>> photoUrlsStream(String albumId) {
    return FirebaseFirestore.instance
        .collection('albums')
        .doc(albumId)
        .collection('photos')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d['url'] as String).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Albums')),
      body:
          loadingAlbums
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Album selector dropdown
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Select Album'),
                      value: selectedAlbumId,
                      items:
                          albums.map((doc) {
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(doc['title']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedAlbumId = value;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Photo grid
                  Expanded(
                    child:
                        selectedAlbumId == null
                            ? const Center(
                              child: Text('Select an album to view photos'),
                            )
                            : StreamBuilder<List<String>>(
                              stream: photoUrlsStream(selectedAlbumId!),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final photos = snapshot.data ?? [];
                                if (photos.isEmpty) {
                                  return const Center(
                                    child: Text('No photos in this album'),
                                  );
                                }
                                return PhotoGrid(photos: photos);
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
*/
