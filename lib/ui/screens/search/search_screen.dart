import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../services/auth_service.dart';
import '../../../../../services/friendships_service.dart';
import '../../../core/result.dart';
import '../../../core/typedefs.dart';
import '../../../entities/friendship.dart';
import '../../../failures/failure.dart';
import '../../shared/dialogs/loader_dialog.dart';
import '../../shared/validators/form_validator.dart';
import '../../shared/widgets/user_list.dart';
import '../../shared/widgets/user_tile.dart';
import '../home/tabs/requests/widgets/request_tile.dart';
import 'widgets/app_bar.dart';

sealed class SearchState {
  const SearchState();
}

class SearchLoadingState extends SearchState {
  const SearchLoadingState();
}

class SearchLoadedState extends SearchState {
  const SearchLoadedState({required this.friendshipsData});
  final List<FriendshipsData> friendshipsData;
}

class SearchLoadErrorState extends SearchState {
  const SearchLoadErrorState({required this.failure});
  final Failure failure;
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  static const String route = '/search';

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  SearchState state = const SearchLoadingState();

  final friendshipsService = FriendshipsService(FirebaseFirestore.instance);
  final userService = AuthService(FirebaseAuth.instance);
  late final currentUserId = userService.currentUser!.id;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(loadFrienshipRequest);
    super.initState();
  }

  Future<void> loadFrienshipRequest(Duration _) async {
    state = const SearchLoadingState();
    setState(() {});
    final result = await friendshipsService.getFriendshipRequests(
      currentUserId,
    );
    state = switch (result) {
      Success(value: final friendshipsData) => SearchLoadedState(
          friendshipsData: friendshipsData,
        ),
      Error(value: final failure) => SearchLoadErrorState(
          failure: failure,
        ),
    };
    setState(() {});
  }

  Future<void> searchUser(String email) async {
    state = const SearchLoadingState();
    setState(() {});
    final result = await friendshipsService.searchUsers(currentUserId, email);
    state = switch (result) {
      Success(value: final friendshipData) => SearchLoadedState(
          friendshipsData: [friendshipData],
        ),
      Error(value: final failure) => SearchLoadErrorState(failure: failure),
    };
    setState(() {});
  }

  Future<void> acceptFriendshipRequest(FriendshipsData friendshipData) async {
    final result = await showLoader(
      context,
      friendshipsService.acceptFriendshipRequest(friendshipData.friendship!.id),
    );
    friendshipActionResultToState(result, friendshipData);
  }

  Future<void> rejectFriendshipRequest(FriendshipsData friendshipData) async {
    final result = await showLoader(
      context,
      friendshipsService.rejectFriendshipRequest(friendshipData.friendship!.id),
    );
    friendshipActionResultToState(result, friendshipData);
  }

  void friendshipActionResultToState(
    Result<void, Failure> result,
    FriendshipsData friendshipData,
  ) {
    final friendshipsData = switch (result) {
      Success() => [...data]..remove(friendshipData),
      Error() => data,
    };
    state = SearchLoadedState(friendshipsData: friendshipsData);
    setState(() {});
  }

  Future<void> sendFriendshipRequest(FriendshipsData friendshipData) async {
    final result = await showLoader(
      context,
      friendshipsService.sendFriendshipRequest(
        sender: currentUserId,
        recipientId: friendshipData.user.id,
      ),
    );
    final friendshipsData = switch (result) {
      Success(value: final friendship) => addNewFriendship(
          friendshipData,
          friendship,
        ),
      Error() => data,
    };
    state = SearchLoadedState(friendshipsData: friendshipsData);
    setState(() {});
  }

  List<FriendshipsData> addNewFriendship(
    FriendshipsData friendshipData,
    Friendship friendship,
  ) {
    final friendshipsData = [...data];
    final index = friendshipsData.indexWhere(
      (f) => f.user.id == friendshipData.user.id,
    );
    if (index != -1) {
      friendshipsData[index] = (
        user: friendshipsData[index].user,
        friendship: friendship,
      );
    }
    return friendshipsData;
  }

  Future<void> cancelFriendshipRequest(FriendshipsData friendshipData) async {
    final friendship = friendshipData.friendship!;
    final canceled = await showLoader(
      context,
      friendshipsService.cancelFriendshipRequest(friendship.id),
    );
    final friendsData = switch (canceled) {
      Success() => addNewFriendship(
          friendshipData,
          Friendship(
            id: friendship.id,
            users: friendship.users,
            sender: friendship.sender,
            status: FriendshipStatus.archived,
            createdAt: friendship.createdAt,
            updatedAt: DateTime.now(),
          ),
        ),
      Error() => data,
    };
    state = SearchLoadedState(friendshipsData: friendsData);
    setState(() {});
  }

  List<FriendshipsData> get data => switch (state) {
        SearchLoadedState(friendshipsData: final data) => data,
        _ => <FriendshipsData>[],
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(onSearch: (email) {
        if (email.isEmpty) {
          loadFrienshipRequest(Duration.zero);
        }
        if (FormValidator.email(email) == null) {
          searchUser(email);
        }
      }),
      body: switch (state) {
        SearchLoadingState() => const Center(
            child: CircularProgressIndicator(),
          ),
        SearchLoadedState(friendshipsData: final data) when data.isEmpty =>
          const Center(child: Text("You still don't have friendship request")),
        SearchLoadedState(friendshipsData: final data) => UserList(
            data: data,
            itemBuilder: (_, friendshipData) {
              final friendship = friendshipData.friendship;
              final status = friendship?.status;
              return switch (status) {
                null || FriendshipStatus.archived => UserTile(
                    onPressed: () => sendFriendshipRequest(friendshipData),
                    user: friendshipData.user,
                    trailingIcon: Icons.person_add_alt_1_outlined,
                  ),
                FriendshipStatus.pending
                    when friendship?.sender == currentUserId =>
                  UserTile(
                    onPressed: () => cancelFriendshipRequest(friendshipData),
                    user: friendshipData.user,
                    trailingIcon: Icons.person_remove_alt_1_outlined,
                  ),
                FriendshipStatus.pending => RequestTile(
                    onAccept: () => acceptFriendshipRequest(friendshipData),
                    onReject: () => rejectFriendshipRequest(friendshipData),
                    username: friendshipData.user.username ?? '',
                    email: friendshipData.user.email ?? '',
                    photoUrl: friendshipData.user.photoUrl,
                  ),
                FriendshipStatus.active => UserTile(
                    onPressed: () => cancelFriendshipRequest(friendshipData),
                    user: friendshipData.user,
                  ),
              };
            },
          ),
        SearchLoadErrorState(failure: final failure) =>
          Center(child: Text(failure.message)),
      },
    );
  }
}
