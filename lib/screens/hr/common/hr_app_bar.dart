import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HrAppBar extends AppBar {
  HrAppBar({
    super.key,
    required BuildContext context,
    required String titleText,
    VoidCallback? onRefresh,
  }) : super(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/hr');
              }
            },
          ),
          title: Text(titleText),
          actions: [
            if (onRefresh != null)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
              ),
          ],
        );
}


