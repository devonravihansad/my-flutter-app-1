import 'package:cloud_firestore/cloud_firestore.dart';

class AlbumRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getAlbumPhotos(String albumId) {
    return _firestore
        .collection('albums')
        .doc(albumId)
        .collection('photos')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }
}
