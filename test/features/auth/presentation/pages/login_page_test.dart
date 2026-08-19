// Same provider-override technique as the other widget tests — avoids
// booting real Firebase Auth for a pure form-validation check.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:machinetestsecond/features/auth/presentation/pages/login_page.dart';
import 'package:machinetestsecond/features/auth/presentation/providers/auth_form_notifier.dart';
import 'package:machinetestsecond/features/auth/presentation/providers/auth_form_state.dart';

class _FakeAuthFormNotifier extends AuthFormNotifier {
  @override
  AuthFormState build() => const AuthFormState.initial();
}

void main() {
  testWidgets('empty email and password block submit', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authFormNotifierProvider.overrideWith(() => _FakeAuthFormNotifier()),
        ],
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });
}
