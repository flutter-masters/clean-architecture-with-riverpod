import 'package:flutter/material.dart';

import '../../../../../shared/theme/palette.dart';

class FriendTile extends StatelessWidget {
  const FriendTile({
    super.key,
    required this.onDelete,
  });

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: Palette.dark,
      leading: const CircleAvatar(),
      title: const Text('username'),
      subtitle: const Text('user@email.com'),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete),
      ),
    );
  }
}
