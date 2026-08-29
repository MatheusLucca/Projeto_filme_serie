import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/titles_provider.dart';
import 'screens/home_screen.dart';

void main() {
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
      ),
    );
  }
}
