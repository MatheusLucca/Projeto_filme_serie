import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/titles_provider.dart';
import 'screens/home_screen.dart';
import 'widgets/error_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // By default, release builds render a blank box when a widget throws
  // during build (Flutter only shows the red error screen in debug mode)
  // and print nothing anywhere the user can see. Route every error we can
  // catch — widget build failures and uncaught async/platform errors —
  // into an on-screen banner so problems are visible on a real device
  // without needing to attach a debugger.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.red.shade900,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Text(
        details.exceptionAsString(),
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  };
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    GlobalErrorNotifier.instance.report(details.exceptionAsString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    GlobalErrorNotifier.instance.report(error);
    return true;
  };

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env is optional — app works fine without a default TMDB key,
    // the user can paste one in Settings instead.
  }
  runApp(const WatchlistApp());
}

class WatchlistApp extends StatelessWidget {
  const WatchlistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TitlesProvider(),
      child: MaterialApp(
        title: 'Minha Watchlist',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        builder: (context, child) => ErrorBannerOverlay(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
