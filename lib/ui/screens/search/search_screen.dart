import 'package:flutter/material.dart';

import 'widgets/app_bar.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SearchAppBar(
        onSearch: (_) {},
      ),
    );
  }
}
