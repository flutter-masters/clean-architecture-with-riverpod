import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../../entities/app_user.dart';
import '../../../../../services/auth_service.dart';
import '../../../../../services/users_service.dart';
import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/theme/palette.dart';
import '../../../auth/auth_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  AppUser? currentUser;
  var loading = true;
  late final authService = AuthService(FirebaseAuth.instance);
  late final usersService = UsersService(FirebaseFirestore.instance);

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback(loadUser);
    super.initState();
  }

  Future<void> loadUser(Duration _) async {
    final user = await usersService.getUserById(
      authService.currentUser!.id,
    );
    loading = false;
    currentUser = user;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 50),
              if (loading) ...[
                const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else ...[
                const CircleAvatar(radius: 50),
                const SizedBox(height: 10),
                Text(
                  currentUser?.username ?? '',
                  textAlign: TextAlign.center,
                ),
                Text(
                  currentUser?.email ?? '',
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: Palette.darkGray,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    authService.logout().whenComplete(
                      () {
                        context.pushNamedAndRemoveUntil(AuthScreen.route);
                      },
                    );
                  },
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Palette.darkGray),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Palette.pink),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
