import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/avatar_service.dart';
import '../services/profile_prefs.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _saving = false;
  String? _avatarUrl;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    final u = _user;
    _nameCtrl.text = u?.displayName ?? '';
    // Load stored location
    ProfilePrefs.instance.getLocation().then((loc) {
      if (loc != null && mounted) {
        _locationCtrl.text = loc;
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();
      if (name.isNotEmpty) {
        await AvatarService.instance.updateDisplayName(name);
      }
      await ProfilePrefs.instance.setLocation(_locationCtrl.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickAvatar() async {
    setState(() => _saving = true);
    try {
      final url = await AvatarService.instance.pickAndUpload();
      if (url != null) {
        setState(() => _avatarUrl = url);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 54,
                      backgroundColor: const Color(0xFF1E1E22),
                      backgroundImage: (_avatarUrl ?? u?.photoURL) != null ? NetworkImage(_avatarUrl ?? u!.photoURL!) : null,
                      child: (_avatarUrl ?? u?.photoURL) == null ? const Icon(Icons.person, color: Colors.white54, size: 48) : null,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _saving ? null : _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5DA2),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(.4), blurRadius: 10)],
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration('Display Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Enter a name' : null,
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _locationCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _fieldDecoration('Location (optional)'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.shade400,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1E1E22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }
}
