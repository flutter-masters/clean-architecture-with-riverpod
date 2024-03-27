import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../core/result.dart';
import '../../../../../entities/app_user.dart';
import '../../../../../failures/failure.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/users_service.dart';
import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/theme/palette.dart';
import '../../../auth/auth_screen.dart';

sealed class UserState {
  const UserState();
}

class UserLoadingState extends UserState {
  const UserLoadingState();
}

class UserLoadedState extends UserState {
  const UserLoadedState({required this.user});
  final AppUser user;
}

class UserLoadErrorState extends UserState {
  const UserLoadErrorState({required this.failure});
  final Failure failure;
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  UserState state = const UserLoadingState();
  late final authService = AuthService(FirebaseAuth.instance);
  late final usersService = UsersService(FirebaseFirestore.instance);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(loadUser);
    super.initState();
  }

  Future<void> loadUser(Duration _) async {
    final result = await usersService.getUserById(
      authService.currentUser!.id,
    );
    state = switch (result) {
      Success(value: final user) => UserLoadedState(user: user),
      Error(value: final failure) => UserLoadErrorState(failure: failure),
    };
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: switch (state) {
            UserLoadingState() => const Center(
                child: CircularProgressIndicator(),
              ),
            UserLoadedState(user: final user) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 50),
                  const CircleAvatar(radius: 50),
                  const SizedBox(height: 10),
                  Text(
                    user.username ?? '',
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    user.email ?? '',
                    style: context.theme.textTheme.bodyMedium?.copyWith(
                      color: Palette.darkGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => authService.logout().whenComplete(
                      () {
                        context.pushNamedAndRemoveUntil(AuthScreen.route);
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.darkGray,
                    ),
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Palette.pink),
                    ),
                  ),
                ],
              ),
            UserLoadErrorState(failure: final failure) => Center(
                child: Text(failure.message),
              ),
          },
        ),
      ),
    );
  }
}
