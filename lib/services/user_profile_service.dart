import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';

class UserProfileService {
  UserProfileService._();
  static final instance = UserProfileService._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  Future<UserProfile?> current() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final ref = _col.doc(user.uid);
    final doc = await ref.get();
    if (!doc.exists) {
      final data = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName ?? 'User',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      try {
        await ref.set(data, SetOptions(merge: true));
      } catch (_) {}
      return UserProfile.fromMap(data);
    }
    return UserProfile.fromMap(doc.data()!);
  }

  Future<UserProfile> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    await user.updateDisplayName(name);
    final ref = _col.doc(user.uid);
    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      await ref.set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied writing user profile. Please adjust Firestore rules.');
      }
      rethrow;
    }

    // Fire and forget backfill
    // ignore: unawaited_futures
    _backfillUserName(user.uid, name);

    return UserProfile.fromMap(data);
  }

  Future<void> _backfillUserName(String uid, String newName) async {
    try {
      final batch = _db.batch();
      final ordersSnap = await _db.collection('orders')
          .where('userId', isEqualTo: uid)
          .limit(50)
          .get();
      for (final d in ordersSnap.docs) {
        if (d.data()['userName'] != newName) {
          batch.update(d.reference, {'userName': newName});
        }
      }
      final ticketsSnap = await _db.collection('tickets')
          .where('userId', isEqualTo: uid)
          .limit(100)
          .get();
      for (final d in ticketsSnap.docs) {
        if (d.data()['userName'] != newName) {
          batch.update(d.reference, {'userName': newName});
        }
      }
      await batch.commit();
    } catch (_) {
      // ignore; non-critical
    }
  }
}
