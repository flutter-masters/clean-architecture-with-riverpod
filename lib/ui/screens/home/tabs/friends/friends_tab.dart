import 'package:flutter/material.dart';

import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/theme/palette.dart';
import '../../../search/search_screen.dart';
import 'widgets/app_bar.dart';
import 'widgets/friend_tile.dart';

class FriendsTab extends StatelessWidget {
  const FriendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          FriendsAppbar(
            onAdd: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
            },
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemBuilder: (_, index) {
                return FriendTile(
                  onDelete: () {},
                );
              },
              separatorBuilder: (_, __) => const Divider(
                color: Palette.darkGray,
                height: 1,
              ),
              itemCount: 100,
            ),
          ),
        ],
      ),
    );
  }
}
