// Basic smoke test for the Task List screen. Overrides the notifier
// provider directly instead of booting real Firebase/Hive plugins, since
// those platform channels aren't available under plain `flutter test`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:machinetestsecond/features/tasks/domain/entities/task_entity.dart';
import 'package:machinetestsecond/features/tasks/presentation/pages/task_list_page.dart';
import 'package:machinetestsecond/features/tasks/presentation/providers/task_list_filter.dart';
import 'package:machinetestsecond/features/tasks/presentation/providers/task_list_notifier.dart';
import 'package:machinetestsecond/features/tasks/presentation/providers/task_list_state.dart';

final _testTask = TaskEntity(
  id: 'test-id',
  title: 'Write the report',
  description: 'Quarterly summary',
  priority: TaskPriority.high,
  dueDate: DateTime(2026, 1, 1),
  isCompleted: false,
  createdAt: DateTime(2025, 12, 1),
);

class _FakeTaskListNotifier extends TaskListNotifier {
  @override
  TaskListState build() => TaskListState(
        isLoading: false,
        allTasks: [_testTask],
        filteredTasks: [_testTask],
        searchQuery: '',
        filter: TaskFilter.all,
        sortBy: TaskSortOption.dueDate,
        isSyncing: false,
      );
}

void main() {
  testWidgets('TaskListPage renders tasks from the notifier', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          taskListNotifierProvider.overrideWith(() => _FakeTaskListNotifier()),
        ],
        child: const MaterialApp(home: TaskListPage()),
      ),
    );
    await tester.pump();

    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Write the report'), findsOneWidget);
  });
}
