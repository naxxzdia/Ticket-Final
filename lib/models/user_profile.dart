class UserProfile {
  final String uid;
  final String? email;
  final String displayName;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.displayName,
    this.email,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'updatedAt': DateTime.now().toUtc(),
  };

  static DateTime? _parseTs(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toUtc();
    try {
      // Firestore Timestamp support without importing (dynamic access)
      if (v.runtimeType.toString() == 'Timestamp') {
        final seconds = (v as dynamic).seconds as int?; // ignore: avoid_dynamic_calls
        final nanoseconds = (v as dynamic).nanoseconds as int?; // ignore: avoid_dynamic_calls
        if (seconds != null) {
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ?? 0) ~/ 1000000, isUtc: true);
        }
      }
    } catch (_) {}
    try { return DateTime.tryParse(v.toString())?.toUtc(); } catch (_) { return null; }
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] ?? '',
    email: map['email'],
    displayName: map['displayName'] ?? '',
    updatedAt: _parseTs(map['updatedAt']),
  );

  UserProfile copyWith({String? displayName}) => UserProfile(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    updatedAt: DateTime.now().toUtc(),
  );
}
