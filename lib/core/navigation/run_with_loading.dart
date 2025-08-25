import 'package:flutter/material.dart';
import '../../ui/screens/loading_screen.dart';

/// Muestra la LoadingScreen como *modal* (no entra en el backstack)
/// ejecuta [task], garantiza un tiempo mínimo visible y cierra solo el modal.
///
/// Ejemplo:
/// final result = await runWithLoading(context, () => apiCall());
Future<T> runWithLoading<T>(
  BuildContext context,
  Future<T> Function() task, {
  int minShowMs = 700, // ajustable
}) async {
  final nav = Navigator.of(context, rootNavigator: true);
  final started = DateTime.now();

  // Abre el modal a pantalla completa (no back, no tap fuera)
  showGeneralDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: 'loading',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (_, __, ___) => const LoadingScreen(),
  );

  try {
    final T result = await task();
    return result;
  } finally {
    final elapsed = DateTime.now().difference(started).inMilliseconds;
    final wait = minShowMs - elapsed;
    if (wait > 0) {
      await Future.delayed(Duration(milliseconds: wait));
    }
    if (nav.canPop()) {
      nav.pop(); // cierra SOLO el modal de carga
    }
  }
}
