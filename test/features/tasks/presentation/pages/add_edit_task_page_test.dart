// Overrides the notifier provider directly (same technique as the top-level
// widget_test.dart) rather than registering real usecases into `sl` —
// validation failing means submit() is never called, so the notifier's
// dependencies never need to exist for this test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:machinetestsecond/features/tasks/presentation/pages/add_edit_task_page.dart';
import 'package:machinetestsecond/features/tasks/presentation/providers/add_edit_task_notifier.dart';
import 'package:machinetestsecond/features/tasks/presentation/providers/add_edit_task_state.dart';

class _FakeAddEditTaskNotifier extends AddEditTaskNotifier {
  @override
  AddEditTaskState build() => const AddEditTaskState.initial();
}

void main() {
  testWidgets('empty title blocks submit and shows a validation message',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          addEditTaskNotifierProvider
              .overrideWith(() => _FakeAddEditTaskNotifier()),
        ],
        child: const MaterialApp(home: AddEditTaskPage()),
      ),
    );

    await tester.tap(find.text('Create task'));
    await tester.pump();

    expect(find.text('Title is required'), findsOneWidget);
  });
}
