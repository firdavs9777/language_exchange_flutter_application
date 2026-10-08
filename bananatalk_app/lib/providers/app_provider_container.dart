import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app's single Riverpod container, mounted by `main()` through
/// `UncontrolledProviderScope`.
///
/// It exists so code that runs outside the widget tree -- ApiClient's
/// session-expired and account-suspended callbacks, wired in `main()` before
/// `runApp` -- can reset user-scoped providers (see `resetUserSession`).
/// Widgets keep using `ref`; it is the same container.
final ProviderContainer appProviderContainer = ProviderContainer();
