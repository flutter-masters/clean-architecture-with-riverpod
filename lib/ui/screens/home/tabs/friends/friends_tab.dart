import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../core/result.dart';
import '../../../../../core/typedefs.dart';
import '../../../../../failures/failure.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/friendships_service.dart';
import '../../../../shared/dialogs/loader_dialog.dart';
import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/widgets/user_list.dart';
import '../../../../shared/widgets/user_tile.dart';
import '../../../search/search_screen.dart';
import 'widgets/app_bar.dart';

sealed class FriendsState {
  const FriendsState();
}

class FriendsLoadingState extends FriendsState {
  const FriendsLoadingState();
}

class FriendsLoadedState extends FriendsState {
  const FriendsLoadedState({required this.friendsData});
  final List<FriendshipsData> friendsData;
}

class FriendsLoadErrorState extends FriendsState {
  const FriendsLoadErrorState({required this.failure});
  final Failure failure;
}

class FriendsTab extends StatefulWidget {
  const FriendsTab({super.key});

  @override
  State<FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<FriendsTab> {
  FriendsState state = const FriendsLoadingState();
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
    state = switch (result) {
      Success(value: final friendsData) => FriendsLoadedState(
          friendsData: friendsData,
        ),
      Error(value: final failure) => FriendsLoadErrorState(
          failure: failure,
        ),
    };
    setState(() {});
  }

  Future<void> onDelete(FriendshipsData friendshipData) async {
    final deleted = await showLoader(
      context,
      friendshipsService.cancelFriendshipRequest(
        friendshipData.friendship!.id,
      ),
    );
    final friendsData = switch (deleted) {
      Success() => [...data]..remove(friendshipData),
      Error() => data,
    };
    state = FriendsLoadedState(friendsData: friendsData);
    setState(() {});
  }

  List<FriendshipsData> get data => switch (state) {
        FriendsLoadedState(friendsData: final friendsData) => friendsData,
        _ => [],
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          FriendsAppbar(onAdd: () => context.pushNamed(SearchScreen.route)),
          Expanded(
            child: switch (state) {
              FriendsLoadingState() => const Center(
                  child: CircularProgressIndicator(),
                ),
              FriendsLoadedState(friendsData: final friendsData)
                  when friendsData.isEmpty =>
                const Center(
                  child: Text("You still don't have friends"),
                ),
              FriendsLoadedState(friendsData: final friendsData) =>
                UserList<FriendshipsData>(
                  data: friendsData,
                  itemBuilder: (_, friendData) => UserTile(
                    onPressed: () => onDelete(friendData),
                    user: friendData.user,
                  ),
                ),
              FriendsLoadErrorState(failure: final failure) => Center(
                  child: Text(failure.message),
                ),
            },
          ),
        ],
      ),
    );
  }
}
