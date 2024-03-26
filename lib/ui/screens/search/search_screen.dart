import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../services/auth_service.dart';
import '../../../../../services/friendships_service.dart';
import '../../../../../services/users_service.dart';
import '../../../entities/app_user.dart';
import '../../shared/dialogs/loader_dialog.dart';
import '../../shared/widgets/user_list.dart';
import '../../shared/widgets/user_tile.dart';
import '../home/tabs/requests/widgets/request_tile.dart';
import 'widgets/app_bar.dart';

enum SearchState { initial, searching, searched }

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  static const String route = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var loading = true;
  var state = SearchState.initial;
  var users = <AppUser>[];
  var pendingsRequestsSentIds = <String, String>{};
  var friendsIds = <String, String>{};
  final friendships = <AppUser>[];
  final pendingsRequestsIds = <String, String>{};

  final friendshipsService = FriendshipsService(FirebaseFirestore.instance);
  final authService = AuthService(FirebaseAuth.instance);
  final usersService = UsersService(FirebaseFirestore.instance);
  AppUser? currentUser;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(loadFriendships);
    super.initState();
  }

  Future<void> loadFriendships(Duration _) async {
    currentUser ??= await usersService.getUserById(authService.currentUser!.id);
    final data = await friendshipsService.getFriendshipRequests(
      currentUser!.id,
    );
    friendships.addAll(data.users ?? []);
    pendingsRequestsIds.addAll(data.friendships ?? {});
    loading = false;
    setState(() {});
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      loading = false;
      state = SearchState.initial;
      users = [];
      friendsIds = {};
      pendingsRequestsSentIds = {};
      return setState(() {});
    }
    loading = true;
    state = SearchState.searching;
    setState(() {});
    final result = await friendshipsService.searchUsers(currentUser!.id);
    loading = false;
    state = SearchState.searched;
    users = (result.users ?? [])
        .where(
          (user) =>
              (user.username ?? '').toLowerCase().contains(query) ||
              (user.email ?? '').toLowerCase().contains(query),
        )
        .toList();
    friendsIds = result.friendsIds ?? {};
    pendingsRequestsSentIds = result.pendingsRequestsSentIds ?? {};
    setState(() {});
  }

  Widget itemBuilder(BuildContext context, AppUser user) {
    final userId = user.id;
    final friend = friendsIds[userId];
    if (friend != null) {
      return UserTile(
        onPressed: () => deletedFriendshipRequest(friend, userId),
        user: user,
      );
    }
    final pendingRequestId = pendingsRequestsIds[userId];
    if (pendingRequestId != null) {
      return RequestTile(
        onAccept: () => acceptFriendshipRequest(user),
        onReject: () => rejectFriendshipRequest(user),
        email: user.email ?? '',
        username: user.username ?? '',
        photoUrl: user.photoUrl,
      );
    }
    final pendingsRequestsSentId = pendingsRequestsSentIds[userId];
    if (pendingsRequestsSentId != null) {
      return UserTile(
        onPressed: () => cancelFriendshipRequest(
          pendingsRequestsSentId,
          userId,
        ),
        user: user,
        trailingIcon: Icons.person_remove,
      );
    }
    return UserTile(
      onPressed: () => sendFriendshipRequest(userId),
      user: user,
      trailingIcon: Icons.person_add_alt_1,
    );
  }

  Future<void> deletedFriendshipRequest(
    String friendshipId,
    String userId,
  ) async {
    final deleted = await showLoader(
      context,
      friendshipsService.cancelFriendshipRequest(friendshipId),
    );
    if (deleted) {}
  }

  Future<void> acceptFriendshipRequest(AppUser user) async {
    final userId = user.id;
    final accepted = await showLoader(
      context,
      friendshipsService.acceptFriendshipRequest(pendingsRequestsIds[userId]!),
    );
    if (accepted) {
      pendingsRequestsIds.remove(userId);
      friendships.remove(user);
      setState(() {});
    }
  }

  Future<void> rejectFriendshipRequest(AppUser user) async {
    final userId = user.id;
    final rejected = await showLoader(
      context,
      friendshipsService.rejectFriendshipRequest(pendingsRequestsIds[userId]!),
    );
    if (rejected) {
      pendingsRequestsIds.remove(userId);
      friendships.remove(user);
      setState(() {});
    }
  }

  Future<void> cancelFriendshipRequest(
    String friendshipId,
    String userId,
  ) async {
    final canceled = await showLoader(
      context,
      friendshipsService.cancelFriendshipRequest(friendshipId),
    );
    if (canceled) {
      pendingsRequestsSentIds.remove(userId);
      setState(() {});
    }
  }

  Future<void> sendFriendshipRequest(String userId) async {
    final friendship = await showLoader(
      context,
      friendshipsService.sendFriendshipRequest(
        sender: currentUser!,
        recipientId: userId,
      ),
    );
    if (friendship != null) {
      pendingsRequestsSentIds.addAll({userId: friendship.id});
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(onSearch: search),
      body: switch (state) {
        SearchState.initial when loading => const Center(
            child: CircularProgressIndicator(),
          ),
        SearchState.initial when friendships.isEmpty => const Center(
            child: Text("You still don't have friendship request"),
          ),
        SearchState.initial => UserList<AppUser>(
            data: friendships,
            itemBuilder: (_, friendship) => RequestTile(
              onAccept: () => acceptFriendshipRequest(friendship),
              onReject: () => rejectFriendshipRequest(friendship),
              username: friendship.username!,
              email: friendship.email!,
              photoUrl: friendship.photoUrl,
            ),
          ),
        SearchState.searching => const Center(
            child: CircularProgressIndicator(),
          ),
        SearchState.searched when users.isEmpty => const Center(
            child: Text("No result found"),
          ),
        SearchState.searched => UserList<AppUser>(
            data: users,
            itemBuilder: itemBuilder,
          ),
      },
    );
  }
}
