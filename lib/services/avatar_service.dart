import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Handles picking an image from gallery/camera and uploading to Firebase Storage.
/// Returns the download URL once uploaded and user profile updated.
class AvatarService {
  AvatarService._();
  static final instance = AvatarService._();

  final _picker = ImagePicker();

  Future<String?> pickAndUpload({bool camera = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final source = camera ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(source: source, maxWidth: 600, imageQuality: 82);
    if (picked == null) return null;
    final file = File(picked.path);
    final ref = FirebaseStorage.instance.ref().child('users').child(user.uid).child('avatar.jpg');
    await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final url = await ref.getDownloadURL();
    await user.updatePhotoURL(url);
    await user.reload();
    return url;
  }

  Future<void> updateDisplayName(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.updateDisplayName(name.trim());
    await user.reload();
  }
}
