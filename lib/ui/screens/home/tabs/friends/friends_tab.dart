import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../entities/app_user.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/friendships_service.dart';
import '../../../../shared/dialogs/loader_dialog.dart';
import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/widgets/user_list.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../search/search_screen.dart';
import 'widgets/app_bar.dart';

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  var loading = true;
  final friends = <AppUser>[];
  final friendships = <String, String>{};
  final friendshipsService = FriendshipsService(FirebaseFirestore.instance);
  final userService = AuthService(FirebaseAuth.instance);
  late final userId = userService.currentUser!.id;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(loadFriends);
    super.initState();
  }

  Future<void> loadFriends(Duration _) async {
    final result = await friendshipsService.getFriends(userId);
    if (result.friends != null) {
      friends.addAll(result.friends!);
    }
    if (result.friendships != null) {
      friendships.addAll(result.friendships!);
    }
    loading = false;
    setState(() {});
  }

  Future<void> onDelete(AppUser friend) async {
    final deleted = await showLoader(
      context,
      friendshipsService.deleteFriendship(friendships[friend.id]!),
    );
    if (deleted) {
      friends.remove(friend);
      friendships.remove(friend.id);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          FriendsAppbar(onAdd: () => context.pushNamed(SearchScreen.route)),
          Expanded(
            child: Builder(
              builder: (_) {
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (friends.isEmpty) {
                  return const Center(
                    child: Text("You still don't have friends"),
                  );
                }
                return UserList(
                  data: friends,
                  itemBuilder: (_, user) => UserTile(
                    onPressed: () => onDelete(user),
                    user: user,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
