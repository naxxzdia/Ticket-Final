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
    final doc = await _col.doc(user.uid).get();
    if (!doc.exists) {
      // create a minimal profile if missing
      final profile = UserProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName ?? 'User',
      );
      await _col.doc(user.uid).set(profile.toMap(), SetOptions(merge: true));
      return profile;
    }
    return UserProfile.fromMap(doc.data()!);
  }

  Future<UserProfile> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    // Update FirebaseAuth displayName too
    await user.updateDisplayName(name);

    final data = {
      'uid': user.uid,
      'email': user.email,
      'displayName': name,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
    };
    await _col.doc(user.uid).set(data, SetOptions(merge: true));

    // Optionally trigger background backfill (non-blocking)
    _backfillUserName(user.uid, name);

    return UserProfile.fromMap(data);
  }

  // Best-effort backfill: update orders & tickets userName field if different.
  Future<void> _backfillUserName(String uid, String newName) async {
    try {
      // Update orders
      final ordersSnap = await _db.collection('orders')
        .where('userId', isEqualTo: uid)
        .limit(50) // safety limit
        .get();
      final batch = _db.batch();
      for (final d in ordersSnap.docs) {
        if (d.data()['userName'] != newName) {
          batch.update(d.reference, {'userName': newName});
        }
      }
      // Update tickets
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
      // silently ignore; not critical.
    }
  }
}
