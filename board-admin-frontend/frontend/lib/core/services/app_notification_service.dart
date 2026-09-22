import 'package:flutter/material.dart';

abstract final class AppNotificationService {
  static void success(BuildContext context, String message) {
    _show(context, message, Icons.check_circle_outline_rounded);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Icons.error_outline_rounded, isError: true);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Icons.info_outline_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon, {
    bool isError = false,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).snackBarTheme.backgroundColor,
          content: Row(
            children: [
              Icon(
                icon,
                color: isError
                    ? Theme.of(context).colorScheme.onError
                    : Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: isError
                        ? Theme.of(context).colorScheme.onError
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
