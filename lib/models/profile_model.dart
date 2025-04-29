class Profile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime? lastActive;

  Profile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.lastActive,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      uid: json['uid'] as String,
      displayName: json['displayName'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      lastActive: json['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastActive'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'lastActive': lastActive?.millisecondsSinceEpoch,
    };
  }
}
