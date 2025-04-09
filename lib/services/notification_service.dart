import 'package:flutter/material.dart';
import 'package:adboard/widgets/custom_notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static OverlayEntry? _currentNotification;

  void showNotification(
    BuildContext context, {
    required String message,
    String? subtitle,
    NotificationType type = NotificationType.success,
    Duration duration = const Duration(seconds: 4),
  }) {
    _hideCurrentNotification();

    final overlay = Overlay.of(context);
    _currentNotification = OverlayEntry(
      builder: (context) => CustomNotification(
        message: message,
        subtitle: subtitle,
        type: type,
        duration: duration,
        onDismiss: _hideCurrentNotification,
      ),
    );

    overlay.insert(_currentNotification!);
  }

  void showSuccessNotification(
    BuildContext context, {
    required String message,
    String? subtitle,
  }) {
    showNotification(
      context,
      message: message,
      subtitle: subtitle,
      type: NotificationType.success,
    );
  }

  void showErrorNotification(
    BuildContext context, {
    required String message,
    String? subtitle,
  }) {
    showNotification(
      context,
      message: message,
      subtitle: subtitle,
      type: NotificationType.error,
    );
  }

  void showWarningNotification(
    BuildContext context, {
    required String message,
    String? subtitle,
  }) {
    showNotification(
      context,
      message: message,
      subtitle: subtitle,
      type: NotificationType.warning,
    );
  }

  void showInfoNotification(
    BuildContext context, {
    required String message,
    String? subtitle,
  }) {
    showNotification(
      context,
      message: message,
      subtitle: subtitle,
      type: NotificationType.info,
    );
  }

  void _hideCurrentNotification() {
    _currentNotification?.remove();
    _currentNotification = null;
  }

  // Test notifications
  void showTestNotifications(BuildContext context) {
    showSuccessNotification(
      context,
      message: 'Test Balance Added',
      subtitle: 'Rs. 1000 has been added to your account',
    );

    Future.delayed(const Duration(seconds: 5), () {
      showInfoNotification(
        context,
        message: 'Welcome to AdBoard',
        subtitle: 'Tap to dismiss this notification',
      );
    });

    Future.delayed(const Duration(seconds: 10), () {
      showWarningNotification(
        context,
        message: 'Low Balance Alert',
        subtitle: 'Your balance is below Rs. 500',
      );
    });
  }
}
