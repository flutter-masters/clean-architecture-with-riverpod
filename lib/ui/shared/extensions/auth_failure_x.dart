import 'package:flutter/material.dart';

import '../../../failures/auth_failure.dart';

extension AuthFailureX on AuthFailure {
  ({IconData icon, String message}) get errorData => switch (this) {
        NetworkFailure() => (
            icon: Icons.wifi_off,
            message: 'There was a problem with the network connection',
          ),
        CreateUserFailure() => (
            icon: Icons.person_add_disabled,
            message: 'Failed to create user.',
          ),
        UserNotFoundFailure() => (
            icon: Icons.person_outline,
            message: 'User not found.',
          ),
        EmailExistFailure() => (
            icon: Icons.mark_email_unread_outlined,
            message: 'The email provided already exists.',
          ),
        WeakPasswordFailure() => (
            icon: Icons.no_encryption_gmailerrorred_outlined,
            message: 'The password provided is too weak.',
          ),
        InvalidEmailFailure() => (
            icon: Icons.mark_email_unread_outlined,
            message: 'The email provided is invalid.',
          ),
        InvalidCredentialsFailure() => (
            icon: Icons.no_encryption_gmailerrorred_outlined,
            message: 'Invalid credentials.',
          ),
        UserDisableFailure() => (
            icon: Icons.person_off,
            message: 'Your account has been disabled.'
          ),
        UnknownFailure() => (
            icon: Icons.error_outline,
            message: 'Something went wrong.',
          ),
      };
}
