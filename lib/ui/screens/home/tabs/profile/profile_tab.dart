import 'package:flutter/material.dart';

import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/theme/palette.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            children: [
              const SizedBox(height: 50),
              const CircleAvatar(
                radius: 50,
              ),
              const SizedBox(height: 10),
              const Text('username'),
              Text(
                'user@emai.com',
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  color: Palette.darkGray,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: const ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(Palette.darkGray),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: Palette.pink),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
