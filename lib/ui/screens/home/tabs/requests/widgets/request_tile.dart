import 'package:flutter/material.dart';

import '../../../../../shared/theme/palette.dart';

class RequestTile extends StatelessWidget {
  const RequestTile({
    super.key,
    required this.onAccept,
    required this.onReject,
  });

  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: Palette.dark,
      leading: const CircleAvatar(),
      title: const Text('username'),
      subtitle: const Text('user@email.com'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onAccept,
            icon: const Icon(
              Icons.check,
              color: Palette.green,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onAccept,
            icon: const Icon(
              Icons.close,
              color: Palette.pink,
            ),
          ),
        ],
      ),
    );
  }
}
