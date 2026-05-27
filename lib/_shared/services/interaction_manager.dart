import 'package:flutter/material.dart';
import 'package:checkly/_shared/router/app_router.dart';

class InteractionManager {
  void showWarningToast(String message) {
    final context = appRouter.routerDelegate.navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE65100), // Dark warning orange
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      debugPrint('[InteractionManager] Context is null. Cannot show toast: $message');
    }
  }
}

