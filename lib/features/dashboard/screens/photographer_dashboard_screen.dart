import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wedding_app/features/dashboard/data/multi_photo_batch_uploader.dart';
import 'package:wedding_app/features/auth/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/photo_grid.dart';

class PhotographerDashboardScreen extends StatefulWidget {
  final String photographerId;

  const PhotographerDashboardScreen({super.key, required this.photographerId});

  @override
  State<PhotographerDashboardScreen> createState() =>
      _PhotographerDashboardScreenState();
}

class _PhotographerDashboardScreenState
    extends State<PhotographerDashboardScreen> {
  List<DocumentSnapshot> clients = [];
  List<DocumentSnapshot> albums = [];
  String? selectedClientId;
  String? selectedAlbumId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadClients();
  }

  Future<void> loadClients() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'client')
        .get();

    setState(() {
      clients = snapshot.docs;
      isLoading = false;
    });
  }

  Future<void> loadAlbums(String clientId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('albums')
        .where('clientId', isEqualTo: clientId)
        .get();
    setState(() {
      albums = snapshot.docs;
      selectedAlbumId = null;
    });
  }

  Future<void> createAlbum(String title) async {
    await FirebaseFirestore.instance.collection('albums').add({
      'clientId': selectedClientId,
      'photographerId': widget.photographerId,
      'title': title,
      'createdAt': Timestamp.now(),
    });
    loadAlbums(selectedClientId!);
  }

  void showCreateAlbumDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Album'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Album Title'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                createAlbum(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Photographer Dashboard')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                  onPressed: () async {
                    // final prefs = await SharedPreferences.getInstance();
                    // await prefs.remove(
                    //   'rememberMe',
                    // ); // remove remember preference
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
                // Client selector
                DropdownButton<String>(
                  hint: const Text('Select Client'),
                  value: selectedClientId,
                  items: clients.map((doc) {
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedClientId = value;
                      albums.clear();
                      selectedAlbumId = null;
                    });
                    loadAlbums(value!);
                  },
                ),
                if (selectedClientId != null)
                  Expanded(
                    child: Column(
                      children: [
                        // Album selector
                        DropdownButton<String>(
                          hint: const Text('Select Album'),
                          value: selectedAlbumId,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: showCreateAlbumDialog,
                              child: const Text('Create New Album'),
                            ),
                            const SizedBox(width: 10),
                            if (selectedAlbumId != null)
                              ElevatedButton(
                                onPressed: () {
                                  MultiPhotoBatchUploader(
                                    cloudName: "dyx5bwi1l",
                                    uploadPreset: "ld5gcvxo",
                                    albumId: selectedAlbumId!,
                                    context: context,
                                    batchSize: 5,
                                  ).pickAndUploadMultiple();
                                },
                                child: const Text("Upload Photos"),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Real-time photo grid
                        if (selectedAlbumId != null)
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('albums')
                                  .doc(selectedAlbumId)
                                  .collection('photos')
                                  .orderBy('uploadedAt', descending: true)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                final photos = snapshot.data!.docs
                                    .map((doc) => doc['url'] as String)
                                    .toList();
                                if (photos.isEmpty) {
                                  return const Center(
                                    child: Text('No photos yet'),
                                  );
                                }
                                return PhotoGrid(photos: photos);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
