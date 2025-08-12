// lib/core/repositories/shared_link_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class SharedLink {
  final String id;
  final String albumId;
  final String passkey;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String creatorId;

  SharedLink({
    required this.id,
    required this.albumId,
    required this.passkey,
    required this.expiresAt,
    required this.createdAt,
    required this.creatorId,
  });

  Map<String, dynamic> toMap() => {
    'albumId': albumId,
    'passkey': passkey,
    'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
    'creatorId': creatorId,
  };

  static SharedLink fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SharedLink(
      id: doc.id,
      albumId: data['albumId'],
      passkey: data['passkey'],
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      creatorId: data['creatorId'],
    );
  }
}

class SharedLinkRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Create a share link
  Future<SharedLink> createShareLink({
    required String albumId,
    required String creatorId,
    Duration? validFor, // null = forever
  }) async {
    final id = _uuid.v4();
    final passkey = id.split('-').first.toUpperCase(); // short passkey
    final now = DateTime.now();
    final expiresAt = validFor != null ? now.add(validFor) : null;

    final data = {
      'albumId': albumId,
      'passkey': passkey,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
      'createdAt': Timestamp.fromDate(now),
      'creatorId': creatorId,
    };

    await _firestore.collection('shared_links').doc(id).set(data);

    return SharedLink(
      id: id,
      albumId: albumId,
      passkey: passkey,
      expiresAt: expiresAt,
      createdAt: now,
      creatorId: creatorId,
    );
  }

  /// Validate a passkey and return the SharedLink (or null)
  Future<SharedLink?> getLinkByPasskey(String passkey) async {
    final q = await _firestore
        .collection('shared_links')
        .where('passkey', isEqualTo: passkey)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    final doc = q.docs.first;
    final link = SharedLink.fromDoc(doc);
    if (link.expiresAt != null && link.expiresAt!.isBefore(DateTime.now()))
      return null;
    return link;
  }

  /// Optionally get by link id
  Future<SharedLink?> getLinkById(String id) async {
    final doc = await _firestore.collection('shared_links').doc(id).get();
    if (!doc.exists) return null;
    final link = SharedLink.fromDoc(doc);
    if (link.expiresAt != null && link.expiresAt!.isBefore(DateTime.now()))
      return null;
    return link;
  }
}
