class Friendship {
  Friendship({
    required this.id,
    required this.users,
    required this.sender,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final List<String> users;

  final String sender;

  final FriendshipStatus status;

  final DateTime createdAt;

  final DateTime updatedAt;
}

enum FriendshipStatus { pending, active, archived }
