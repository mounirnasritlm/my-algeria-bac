import 'package:flutter/widgets.dart';

import 'app_controller.dart';

/// Makes app-wide state available to feature screens without coupling their
/// constructors to the root widget.
class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  })  : controller = controller,
        super(notifier: controller);

  final AppController controller;

  static AppController of(BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      throw FlutterError('AppScope was not found above this context.');
    }
    return controller;
  }

  static AppController? maybeOf(
    BuildContext context, {
    bool listen = true,
  }) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<AppScope>()
        : context
            .getElementForInheritedWidgetOfExactType<AppScope>()
            ?.widget as AppScope?;
    return scope?.controller;
  }
}
