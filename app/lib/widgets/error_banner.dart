import 'package:flutter/material.dart';

/// Holds the most recent uncaught error so it can be shown on-screen.
/// This exists because release builds don't show Flutter's debug red
/// screen and don't print to any console the user can see — without
/// this, a crash during widget build or in an unawaited Future is
/// completely invisible on a real device.
class GlobalErrorNotifier extends ValueNotifier<String?> {
  GlobalErrorNotifier._() : super(null);
  static final instance = GlobalErrorNotifier._();

  void report(Object error, [StackTrace? stack]) {
    value = error.toString();
  }

  void clear() => value = null;
}

/// Wrap the app with this to show a persistent, dismissible red banner
/// whenever [GlobalErrorNotifier.instance] has a value.
class ErrorBannerOverlay extends StatelessWidget {
  final Widget child;

  const ErrorBannerOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        ValueListenableBuilder<String?>(
          valueListenable: GlobalErrorNotifier.instance,
          builder: (context, error, _) {
            if (error == null) return const SizedBox.shrink();
            return Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                child: Material(
                  color: Colors.red.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 18),
                          onPressed: GlobalErrorNotifier.instance.clear,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
