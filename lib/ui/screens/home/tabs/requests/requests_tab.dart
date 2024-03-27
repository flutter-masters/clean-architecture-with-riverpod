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
import 'widgets/app_bar.dart';
import 'widgets/request_tile.dart';

sealed class FriendshipRequestsState {
  const FriendshipRequestsState();
}

class FriendshipRequestsLoadingState extends FriendshipRequestsState {
  const FriendshipRequestsLoadingState();
}

class FriendshipRequestsLoadedState extends FriendshipRequestsState {
  const FriendshipRequestsLoadedState({required this.friendshipsData});
  final List<FriendshipsData> friendshipsData;
}

class FriendshipRequestsLoadErrorState extends FriendshipRequestsState {
  const FriendshipRequestsLoadErrorState({required this.failure});
  final Failure failure;
}

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  FriendshipRequestsState state = const FriendshipRequestsLoadingState();
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
    state = switch (result) {
      Success(value: final friendshipsData) => FriendshipRequestsLoadedState(
          friendshipsData: friendshipsData,
        ),
      Error(value: final failure) => FriendshipRequestsLoadErrorState(
          failure: failure,
        ),
    };
    setState(() {});
  }

  Future<void> acceptFriendshipRequest(FriendshipsData friendshipData) async {
    final result = await showLoader(
      context,
      friendshipsService.acceptFriendshipRequest(friendshipData.friendship!.id),
    );
    resultToState(result, friendshipData);
  }

  Future<void> rejectFriendshipRequest(FriendshipsData friendshipData) async {
    final result = await showLoader(
      context,
      friendshipsService.rejectFriendshipRequest(
        friendshipData.friendship!.id,
      ),
    );
    resultToState(result, friendshipData);
  }

  void resultToState(
    Result<void, Failure> result,
    FriendshipsData friendshipData,
  ) {
    final data = switch (state) {
      FriendshipRequestsLoadedState(friendshipsData: final data) => data,
      _ => <FriendshipsData>[],
    };
    final friendshipsData = switch (result) {
      Success() => [...data]..remove(friendshipData),
      Error() => data,
    };
    state = FriendshipRequestsLoadedState(friendshipsData: friendshipsData);
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
            child: switch (state) {
              FriendshipRequestsLoadingState() => const Center(
                  child: CircularProgressIndicator(),
                ),
              FriendshipRequestsLoadedState(friendshipsData: final data)
                  when data.isEmpty =>
                const Center(
                  child: Text("You still don't have friendship request"),
                ),
              FriendshipRequestsLoadedState(friendshipsData: final data) =>
                UserList<FriendshipsData>(
                  data: data,
                  itemBuilder: (_, friendshipData) => RequestTile(
                    onAccept: () => acceptFriendshipRequest(friendshipData),
                    onReject: () => rejectFriendshipRequest(friendshipData),
                    username: friendshipData.user.username ?? '',
                    email: friendshipData.user.email ?? '',
                    photoUrl: friendshipData.user.photoUrl,
                  ),
                ),
              FriendshipRequestsLoadErrorState(failure: final failure) =>
                Center(child: Text(failure.message)),
            },
          ),
        ],
      ),
    );
  }
}
