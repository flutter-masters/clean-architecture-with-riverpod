import 'package:flutter/material.dart';

import '../../../entities/app_user.dart';
import '../theme/palette.dart';

class UserTile extends StatelessWidget {
  const UserTile({
    super.key,
    required this.onPressed,
    required this.user,
    this.trailingIcon = Icons.delete,
  });

  final VoidCallback onPressed;
  final AppUser user;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: Palette.dark,
      leading: const CircleAvatar(),
      title: Text(user.username ?? ''),
      subtitle: Text(user.email ?? ''),
      trailing: IconButton(
        onPressed: onPressed,
        icon: Icon(trailingIcon),
      ),
    );
  }
}
