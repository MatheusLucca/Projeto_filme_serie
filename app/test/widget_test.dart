import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:watchlist/main.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App shows home screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const WatchlistApp());
    await tester.pump();

    expect(find.text('Minha Watchlist'), findsWidgets);
  });
}
