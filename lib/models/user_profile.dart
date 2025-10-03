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

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
    uid: map['uid'] ?? '',
    email: map['email'],
    displayName: map['displayName'] ?? '',
    updatedAt: map['updatedAt'] == null ? null : DateTime.tryParse(map['updatedAt'].toString()),
  );

  UserProfile copyWith({String? displayName}) => UserProfile(
    uid: uid,
    email: email,
    displayName: displayName ?? this.displayName,
    updatedAt: DateTime.now().toUtc(),
  );
}
