import 'package:material_ui/material_ui.dart';

import 'game_mode.dart';
import 'image_guess_game.dart';

// Resim Tahmini Modu 2: tek çizimde iki şampiyon var, ikisini birlikte bul.
// Ekran ve tur mantığı birinci modla aynı (PictureQuizScreen), sadece veri farklı.
class ImageGuessGame2 extends StatelessWidget {
  const ImageGuessGame2({super.key});

  static const _characters = [
    PictureQuestion('assets/images/1a.jpg', 'Thresh - Ahri'),
    PictureQuestion('assets/images/2a.jpg', 'Jinx - Mordekaiser'),
    PictureQuestion('assets/images/3a.jpg', 'Zed - Soraka'),
    PictureQuestion('assets/images/4a.jpg', 'Darius - Janna'),
    PictureQuestion('assets/images/5a.jpg', 'Draven - Morgana'),
    PictureQuestion('assets/images/6a.jpg', 'Elise - Braum'),
    PictureQuestion('assets/images/7a.jpg', 'Shyvana - Ezreal'),
    PictureQuestion('assets/images/8a.jpg', 'Kayn - Lux'),
    PictureQuestion('assets/images/9a.jpg', 'Nasus - Katarina'),
    PictureQuestion('assets/images/10a.jpg', 'Malphite - Janna'),
  ];

  @override
  Widget build(BuildContext context) {
    return const PictureQuizScreen(
      mode: GameMode.imageGuess2,
      questions: _characters,
      prompt: 'Bu hangi iki şampiyon?',
      aspectRatio: 1,
    );
  }
}
