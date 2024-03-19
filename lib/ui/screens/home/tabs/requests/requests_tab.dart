import 'package:flutter/material.dart';

import '../../../../shared/extensions/build_context.dart';
import '../../../../shared/theme/palette.dart';
import 'widgets/app_bar.dart';
import 'widgets/request_tile.dart';

class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          const RequestsAppBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(10),
              itemBuilder: (_, index) {
                return RequestTile(
                  onAccept: () {},
                  onReject: () {},
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
