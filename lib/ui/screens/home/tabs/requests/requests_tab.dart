import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../entities/app_user.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/friendships_service.dart';
import '../../../../shared/dialogs/loader_dialog.dart';
import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/widgets/user_list.dart';
import 'widgets/app_bar.dart';
import 'widgets/request_tile.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  var loading = true;
  final friendshipRequests = <AppUser>[];
  final friendships = <String, String>{};

  final friendshipsService = FriendshipsService(FirebaseFirestore.instance);
  final authService = AuthService(FirebaseAuth.instance);
  late final userId = authService.currentUser!.id;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(loadFrienshipRequest);
    super.initState();
  }

  Future<void> loadFrienshipRequest(Duration _) async {
    final result = await friendshipsService.getFriendshipRequests(userId);
    if (result.users != null) {
      friendshipRequests.addAll(result.users!);
    }
    if (result.friendships != null) {
      friendships.addAll(result.friendships!);
    }
    loading = false;
    setState(() {});
  }

  Future<void> acceptFriendshipRequest(AppUser user) async {
    final accepted = await showLoader(
      context,
      friendshipsService.acceptFriendshipRequest(friendships[user.id]!),
    );
    if (accepted) {
      success(user);
    }
  }

  Future<void> rejectFriendshipRequest(AppUser user) async {
    final accepted = await showLoader(
      context,
      friendshipsService.rejectFriendshipRequest(friendships[user.id]!),
    );
    if (accepted) {
      success(user);
    }
  }

  void success(AppUser user) {
    friendshipRequests.remove(user);
    friendships.remove(user.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          const RequestsAppBar(),
          Expanded(
            child: Builder(
              builder: (_) {
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (friendshipRequests.isEmpty) {
                  return const Center(
                    child: Text("You still don't have friendship request"),
                  );
                }
                return UserList<AppUser>(
                  data: friendshipRequests,
                  itemBuilder: (_, friendship) => RequestTile(
                    onAccept: () => acceptFriendshipRequest(friendship),
                    onReject: () => rejectFriendshipRequest(friendship),
                    username: friendship.username!,
                    email: friendship.email!,
                    photoUrl: friendship.photoUrl,
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
