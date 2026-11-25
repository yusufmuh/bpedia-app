/// Menyediakan [AppServices] ke pohon widget.
library;

import 'package:flutter/widgets.dart';

import 'app_services.dart';

/// Pembawa [AppServices]. Dipasang kerangka app di atas `MaterialApp`.
///
/// Layar mengambil layanan dengan `AppScope.of(context)` lalu mendengarkan
/// repositori yang dibutuhkan (`ListenableBuilder`), karena tiap repositori
/// adalah `ChangeNotifier` sendiri.
class AppScope extends InheritedWidget {
  const AppScope({required this.services, required super.child, super.key});

  /// Layanan app.
  final AppServices services;

  /// Layanan app terdekat. Melempar bila tidak ada [AppScope] di atas
  /// [context].
  static AppServices of(BuildContext context) {
    final services = maybeOf(context);
    assert(services != null, 'AppScope tidak ditemukan di atas widget ini');
    return services!;
  }

  /// Layanan app terdekat, atau null.
  static AppServices? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()?.services;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      !identical(oldWidget.services, services);
}
