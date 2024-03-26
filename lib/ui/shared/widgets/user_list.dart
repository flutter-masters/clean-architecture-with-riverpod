import 'package:flutter/material.dart';

import '../theme/palette.dart';

class UserList<T> extends StatelessWidget {
  const UserList({
    super.key,
    required this.data,
    required this.itemBuilder,
  });
  final List<T> data;
  final Widget Function(BuildContext, T) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) => itemBuilder(context, data[index]),
      separatorBuilder: (_, __) => const Divider(
        color: Palette.darkGray,
        height: 1,
      ),
      itemCount: data.length,
    );
  }
}
