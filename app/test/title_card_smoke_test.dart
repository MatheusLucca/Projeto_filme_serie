import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:watchlist/models/title_item.dart';
import 'package:watchlist/widgets/title_card.dart';

void main() {
  testWidgets('TitleCard (episodic, swipeable) renders inside ListView.builder', (tester) async {
    final item = TitleItem(
      id: 1,
      name: 'Ben 10',
      type: TitleType.serie,
      season: 1,
      episode: 6,
      totalEpisodes: 13,
      totalSeriesEpisodes: 52,
      episodesWatched: 5,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) => TitleCard(
              item: item,
              onTap: () {},
              onAdvanceEpisode: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ben 10'), findsOneWidget);
    expect(find.text('S01 · E06/13'), findsOneWidget);
  });

  testWidgets('TitleCard (movie) renders inside ListView.builder', (tester) async {
    final item = TitleItem(id: 2, name: 'Um Filme', type: TitleType.filme);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            itemCount: 1,
            itemBuilder: (context, index) => TitleCard(
              item: item,
              onTap: () {},
              onMarkWatched: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Um Filme'), findsOneWidget);
  });
}
