class AppUser {
  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.photoUrl,
  });

  final String id;
  final String? username;
  final String? email;
  final String? photoUrl;
}
