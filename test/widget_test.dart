import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riotappv2/game_mode.dart';
import 'package:riotappv2/main.dart';
import 'package:riotappv2/storage.dart';

void main() {
  testWidgets('Menüde dört mod ve en iyi skor görünüyor', (tester) async {
    SharedPreferences.setMockInitialValues({'best_characterHunt': 7});
    await Storage.init();

    tester.view.physicalSize = const Size(1170, 2532); // 390x844, telefon boyutu
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const RiotQuizApp());
    // Test fontu daha geniş olduğu için son kart ekranın altında kalabiliyor
    await tester.scrollUntilVisible(find.text(GameMode.imageGuess2.title), 200);

    for (final mode in GameMode.values) {
      expect(find.text(mode.title), findsOneWidget);
    }
    expect(find.text('En iyi: 7/10'), findsOneWidget);
    expect(find.text('Henüz oynanmadı'), findsNWidgets(3));
  });

  test('Yanlış cevap seriyi sıfırlıyor ama en uzun seri kalıyor', () {
    final round = QuizRound();
    round.record(true);
    round.record(true);
    round.record(false);
    round.record(true);

    expect(round.score, 3);
    expect(round.streak, 1);
    expect(round.bestStreak, 2);
  });
}
