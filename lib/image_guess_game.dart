import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'game_mode.dart';
import 'sounds.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets/quiz_widgets.dart';

// Resim Tahmini Modu: assets/images içindeki çizimlerden şampiyonu tahmin et
class ImageGuessGame extends StatelessWidget {
  const ImageGuessGame({super.key});

  static const _characters = [
    PictureQuestion('assets/images/1.jpg', 'Thresh'),
    PictureQuestion('assets/images/2.jpg', 'Yasuo'),
    PictureQuestion('assets/images/3.jpg', 'Ahri'),
    PictureQuestion('assets/images/4.jpg', 'Soraka'),
    PictureQuestion('assets/images/5.jpg', 'Zed'),
    PictureQuestion('assets/images/6.jpg', 'Teemo'),
    PictureQuestion('assets/images/7.jpg', 'Riven'),
    PictureQuestion('assets/images/8.jpg', 'Heimerdinger'),
    PictureQuestion('assets/images/9.jpg', 'Trundle'),
    PictureQuestion('assets/images/10.jpg', 'Irelia'),
    PictureQuestion('assets/images/11.jpg', 'Zoe'),
    PictureQuestion('assets/images/12.jpg', 'Warwick'),
    PictureQuestion('assets/images/13.jpg', 'Gragas'),
    PictureQuestion('assets/images/14.jpg', "Kha'Zix"),
    PictureQuestion('assets/images/15.jpg', 'Vayne'),
    PictureQuestion('assets/images/16.jpg', 'Nami'),
    PictureQuestion('assets/images/17.jpg', 'Leona'),
    PictureQuestion('assets/images/18.jpg', 'Shen'),
    PictureQuestion('assets/images/19.jpg', 'Jhin'),
    PictureQuestion('assets/images/20.jpg', 'Fiora'),
    PictureQuestion('assets/images/21.jpg', 'Nunu ve Willump'),
    PictureQuestion('assets/images/22.jpg', 'Malphite'),
    PictureQuestion('assets/images/23.jpg', 'Evelynn'),
    PictureQuestion('assets/images/24.jpg', 'Anivia'),
    PictureQuestion('assets/images/25.jpg', 'Darius'),
    PictureQuestion('assets/images/26.jpg', 'Lux'),
    PictureQuestion('assets/images/27.jpg', 'Talon'),
  ];

  @override
  Widget build(BuildContext context) {
    return const PictureQuizScreen(
      mode: GameMode.imageGuess,
      questions: _characters,
      prompt: 'Bu hangi şampiyon?',
      // Çizimler yatay (16:9), kenarlardan biraz kırpınca ekrana daha iyi oturuyor
      aspectRatio: 4 / 3,
    );
  }
}

// Bir resim ve doğru cevabı
class PictureQuestion {
  const PictureQuestion(this.image, this.answer);

  final String image;
  final String answer;
}

// İki Resim Tahmini modunun ortak ekranı. Yanlış şıklar aynı listedeki diğer cevaplardan seçiliyor.
class PictureQuizScreen extends StatefulWidget {
  const PictureQuizScreen({
    super.key,
    required this.mode,
    required this.questions,
    required this.prompt,
    required this.aspectRatio,
  });

  final GameMode mode;
  final List<PictureQuestion> questions;
  final String prompt;
  final double aspectRatio;

  @override
  State<PictureQuizScreen> createState() => _PictureQuizScreenState();
}

class _PictureQuizScreenState extends State<PictureQuizScreen> {
  final _random = Random();

  // Eskiden Future.delayed ile sonraki soruya geçiliyordu ve ekrandan çıkılınca
  // setState çağrılıyordu. Timer'ı tutup dispose'da iptal ediyoruz.
  Timer? _nextTimer;

  late QuizRound _round;
  late List<PictureQuestion> _roundQuestions;
  List<String> _options = [];
  String? _selected;
  bool _answered = false;

  bool _finished = false;
  bool _isNewBest = false;

  PictureQuestion get _current => _roundQuestions[_round.index];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheNext();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    _nextTimer?.cancel();
    final total = min(questionsPerRound, widget.questions.length);
    _round = QuizRound(total: total);
    _roundQuestions = ([...widget.questions]..shuffle(_random)).take(total).toList();
    _finished = false;
    _isNewBest = false;
    _showQuestion();
  }

  void _showQuestion() {
    final correct = _current.answer;
    final options = {correct};
    while (options.length < 4) {
      options.add(widget.questions[_random.nextInt(widget.questions.length)].answer);
    }

    setState(() {
      _options = options.toList()..shuffle(_random);
      _selected = null;
      _answered = false;
    });
    if (mounted && _round.index > 0) _precacheNext();
  }

  // Sıradaki resmi önceden yükle ki geçişte boş kare görünmesin
  void _precacheNext() {
    final next = _round.index + 1;
    if (next < _roundQuestions.length) {
      precacheImage(AssetImage(_roundQuestions[next].image), context);
    }
  }

  void _answer(String option) {
    if (_answered) return;

    final correct = option == _current.answer;
    setState(() {
      _selected = option;
      _answered = true;
      _round.record(correct);
    });
    Sounds.answer(correct);

    _nextTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_round.isLastQuestion) {
        final isNewBest = Storage.saveScore(widget.mode, _round.score);
        setState(() {
          _finished = true;
          _isNewBest = isNewBest;
        });
      } else {
        _round.next();
        _showQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.mode.title)),
      body: _finished
          ? RoundResultView(
              round: _round,
              best: Storage.bestScore(widget.mode) ?? _round.score,
              isNewBest: _isNewBest,
              onReplay: _startRound,
            )
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  GameHeader(
                    round: _round,
                    progress: (_round.index + (_answered ? 1 : 0)) / _round.total,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Expanded(child: Center(child: _buildPicture())),
                          QuestionTitle(widget.prompt),
                          AnswerList(
                            options: _options,
                            correct: _current.answer,
                            selected: _selected,
                            answered: _answered,
                            onSelect: _answer,
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPicture() {
    final borderColor = !_answered
        ? AppColors.goldDim
        : _selected == _current.answer
            ? AppColors.correct
            : AppColors.wrong;

    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.6),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Image.asset(
              _current.image,
              key: ValueKey(_current.image),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
