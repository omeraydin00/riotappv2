import 'dart:async';
import 'dart:math';

import 'package:material_ui/material_ui.dart';

import 'data/champions.dart';
import 'game_mode.dart';
import 'sounds.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets/quiz_widgets.dart';

// Karakter Avı: repliği verilen şampiyonu 10 saniye içinde bul
class CharacterHuntScreen extends StatefulWidget {
  const CharacterHuntScreen({super.key});

  @override
  State<CharacterHuntScreen> createState() => _CharacterHuntScreenState();
}

// Soru ve doğru cevabı temsil eden model sınıf
class CharacterQuestion {
  const CharacterQuestion(this.question, this.correctAnswer);

  final String question;
  final String correctAnswer;
}

// Cevaplar championNames listesindeki yazımla aynı olmalı, yoksa aynı şampiyon şıklarda iki kez çıkar
const _questions = [
  CharacterQuestion("Bu savaş benim başyapıtım olacak.", "Aatrox"),
  CharacterQuestion("Bana güvenmiyor musun?", "Ahri"),
  CharacterQuestion("Soraka acımızı biliyor, ama hissetmememizi, özümüzü inkar etmemizi söylüyor.", "Aphelios"),
  CharacterQuestion("İmparatorunuz geri dönecek.", "Azir"),
  CharacterQuestion("Replikleri sadece ses efektlerinden oluşmaktadır.", "Bard"),
  CharacterQuestion("Gaza geldim, hizmete hazırım.", "Blitzcrank"),
  CharacterQuestion("Dünyayı ateşe vermeye hazır mısın? Heh heh.", "Brand"),
  CharacterQuestion("Cesur ol.", "Braum"),
  CharacterQuestion("Bu iş tam benlik.", "Caitlyn"),
  CharacterQuestion("Gelişim asla bekletilmemeli.", "Camille"),
  CharacterQuestion("Bildiğim dünyanın son bulmasını istiyorsun, evet!", "Cho'Gath"),
  CharacterQuestion("Göreve hazırım. Uçağım da yıkılıyor!", "Corki"),
  CharacterQuestion("Onları yoluma çıktıklarına pişman edeceğim.", "Darius"),
  CharacterQuestion("Yeni bir ay doğuyor.", "Diana"),
  CharacterQuestion("Mundo istediği yere gider.", "Dr. Mundo"),
  CharacterQuestion("Geri çekil, kimi öldürüyoruz? İşimi seviyorum. Hah hah", "Draven"),
  CharacterQuestion("Iıı şey. Havalarda bir tuhaf bu aralar. Bildiğin robot olmuşsun ya.", "Ekko"),
  CharacterQuestion("Onları ağıma düşüreceğim.", "Elise"),
  CharacterQuestion("Vahşetin ortasında şafak vakti açmış bir çiçek gibi ışıldıyorum.", "Jhin"),
  CharacterQuestion("Wujuu benden sorulur.", "Master Yi"),
  CharacterQuestion("Düşmandan yüz çevirmek korkaklıktır.", "Tryndamere"),
  CharacterQuestion("Ölümde rüzgar gibi, hep yanı başımda.", "Yasuo"),
  CharacterQuestion("Havlayan köpek ısırmaz, hav hav hav", "Nasus"),
  CharacterQuestion("Bir keresinde annemi susturmaya çalıştım çalışmaz olaydım.", "Kassadin"),
  CharacterQuestion("Kaptan Teemo göreve hazır.", "Teemo"),
  CharacterQuestion("En büyük sopaya sahip trol kral olur. Kural böyle!", "Trundle"),
  CharacterQuestion("Al sana bir kaya, nereye dayarsan daya.", "Malphite"),
  CharacterQuestion("Herkes bir gün ölümü tadacak, ama bazılarına biraz yardım gerek.", "Lucian"),
  CharacterQuestion("Şimdi nerede kalmıştım? Ah, doğru ya, ortalığı kasıp kavuruyordum!", "Jinx"),
  CharacterQuestion("Onlara su dolu bir mezar göstereceğim.", "Fizz"),
  CharacterQuestion("Bıçakla yaşa ve öl.", "Talon"),
  CharacterQuestion("Bazı şarkılar kafiyeyle başlar, bazıları ritimle... Benimki kalabalıkla başlar.", "Seraphine"),
  CharacterQuestion("Her hata bir derstir.", "Wukong"),
];

const _secondsPerQuestion = 10;

class _CharacterHuntScreenState extends State<CharacterHuntScreen> with SingleTickerProviderStateMixin {
  final _random = Random();

  // Süre çubuğu bir AnimationController ile ilerliyor ve dispose'da duruyor.
  // Eskiden Timer.periodic hiç iptal edilmediği için ekrandan çıkınca setState hatası veriyordu.
  late final AnimationController _clock;
  Timer? _nextTimer;

  late QuizRound _round;
  late List<CharacterQuestion> _roundQuestions;
  List<String> _options = [];
  String? _selected;
  bool _answered = false;
  bool _timedOut = false;

  bool _finished = false;
  bool _isNewBest = false;

  CharacterQuestion get _current => _roundQuestions[_round.index];

  @override
  void initState() {
    super.initState();
    assert(_questions.every((q) => championNames.contains(q.correctAnswer)),
        'Karakter Avı cevaplarından biri şampiyon listesinde yok');

    _clock = AnimationController(vsync: this, duration: const Duration(seconds: _secondsPerQuestion))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_answered) {
          _timedOut = true;
          _answer(null); // Süre doldu, yanlış sayılır
        }
      });
    _startRound();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  void _startRound() {
    _nextTimer?.cancel();
    _round = QuizRound();
    _roundQuestions = ([..._questions]..shuffle(_random)).take(_round.total).toList();
    _finished = false;
    _isNewBest = false;
    _showQuestion();
  }

  void _showQuestion() {
    final correct = _current.correctAnswer;
    final options = {correct};
    // Set kullandığımız için aynı şampiyon iki kez eklenemiyor
    while (options.length < 4) {
      options.add(championNames[_random.nextInt(championNames.length)]);
    }

    setState(() {
      _options = options.toList()..shuffle(_random);
      _selected = null;
      _answered = false;
      _timedOut = false;
    });
    _clock.forward(from: 0);
  }

  void _answer(String? option) {
    if (_answered) return;
    _clock.stop();

    final correct = option == _current.correctAnswer;
    setState(() {
      _selected = option;
      _answered = true;
      _round.record(correct);
    });
    Sounds.answer(correct);

    // Cevabı biraz gösterip sonraki soruya geç
    _nextTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_round.isLastQuestion) {
        _finishRound();
      } else {
        _round.next();
        _showQuestion();
      }
    });
  }

  void _finishRound() {
    final isNewBest = Storage.saveScore(GameMode.characterHunt, _round.score);
    setState(() {
      _finished = true;
      _isNewBest = isNewBest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(GameMode.characterHunt.title)),
      body: _finished
          ? RoundResultView(
              round: _round,
              best: Storage.bestScore(GameMode.characterHunt) ?? _round.score,
              isNewBest: _isNewBest,
              onReplay: _startRound,
            )
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _clock,
                    builder: (context, _) {
                      final left = 1 - _clock.value;
                      return GameHeader(
                        round: _round,
                        progress: left,
                        smooth: false,
                        progressColor: left > 0.3 ? AppColors.teal : AppColors.wrong,
                      );
                    },
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Expanded(child: _buildQuoteCard()),
                          const QuestionTitle('Bu replik hangi şampiyonun?'),
                          AnswerList(
                            options: _options,
                            correct: _current.correctAnswer,
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

  Widget _buildQuoteCard() {
    final correct = _selected == _current.correctAnswer;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldDim.withValues(alpha: 0.7)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHigh, AppColors.surface],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: AppColors.gold, size: 34),
              const Spacer(),
              // Kalan saniye
              AnimatedBuilder(
                animation: _clock,
                builder: (context, _) {
                  final seconds = (_secondsPerQuestion * (1 - _clock.value)).ceil();
                  final color = seconds > 3 ? AppColors.muted : AppColors.wrong;
                  return Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: color),
                      const SizedBox(width: 4),
                      Text('$seconds sn', style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                    ],
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Text(
                  _current.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                    color: AppColors.cream,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 22,
            child: _answered
                ? Text(
                    _timedOut ? 'Süre doldu' : (correct ? 'Doğru!' : 'Yanlış'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: correct ? AppColors.correct : AppColors.wrong,
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
