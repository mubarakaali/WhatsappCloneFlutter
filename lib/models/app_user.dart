class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;

  const AppUser({required this.id, required this.email, required this.displayName, required this.photoUrl});

  factory AppUser.fromMap(String id, Map<String, dynamic> map) => AppUser(
        id: id,
        email: map['email'] as String? ?? '',
        displayName: map['displayName'] as String? ?? 'New User',
        photoUrl: map['photoUrl'] as String?,
      );
}
