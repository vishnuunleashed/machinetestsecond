import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'base_state.dart';

/// Wraps every screen so the loading spinner and error+retry UI are
/// implemented once, here, instead of every page re-writing the same
/// isLoading/errorMessage branch. Pages only supply a [builder] for the
/// "have data" case.
class BaseView<S extends BaseState> extends ConsumerWidget {
  final ProviderListenable<S> provider;
  final Widget Function(BuildContext context, WidgetRef ref, S state) builder;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onRetry;
  final Widget? floatingActionButton;

  const BaseView({
    super.key,
    required this.provider,
    required this.builder,
    this.title,
    this.actions,
    this.onRetry,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(provider);

    return Scaffold(
      appBar: title == null
          ? null
          : AppBar(title: Text(title!), actions: actions),
      body: SafeArea(child: _resolveBody(context, ref, state)),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _resolveBody(BuildContext context, WidgetRef ref, S state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _ErrorView(message: state.errorMessage!, onRetry: onRetry);
    }

    return builder(context, ref, state);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorView({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
