import 'dart:math';

import 'package:material_ui/material_ui.dart';

// Her tur kaç sorudan oluşuyor; dört mod için de aynı
const questionsPerRound = 10;

// Menüde görünen modlar. name alanı en iyi skoru kaydederken anahtar olarak kullanılıyor.
enum GameMode {
  imageChallenge(
    'Resim Mücadelesi',
    'İki bulanık portre tek resimde, ikiliyi bul',
    Icons.blur_on,
  ),
  characterHunt(
    'Karakter Avı',
    'Repliği oku, 10 saniyede sahibini bul',
    Icons.format_quote,
  ),
  imageGuess(
    'Resim Tahmini',
    'Çizimdeki şampiyonu tahmin et',
    Icons.image_search,
  ),
  imageGuess2(
    'Resim Tahmini 2',
    'Tek çizimde iki şampiyon saklı',
    Icons.people_alt_outlined,
  );

  const GameMode(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

// Bir turun skor takibi
class QuizRound {
  QuizRound({this.total = questionsPerRound});

  final int total;
  int index = 0; // şu anki soru, 0'dan başlar
  int score = 0;
  int streak = 0;
  int bestStreak = 0;

  bool get isLastQuestion => index >= total - 1;

  void record(bool correct) {
    if (correct) {
      score++;
      streak++;
      bestStreak = max(bestStreak, streak);
    } else {
      streak = 0;
    }
  }

  void next() => index++;
}
