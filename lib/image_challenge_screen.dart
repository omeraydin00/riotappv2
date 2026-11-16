import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'data/ddragon.dart';
import 'game_mode.dart';
import 'sounds.dart';
import 'storage.dart';
import 'theme.dart';
import 'widgets/quiz_widgets.dart';

// Resim Mücadelesi: iki şampiyonun bulanık portresi tek resimde, ikiliyi bul.
// Seri uzadıkça bulanıklık artıyor, yanlış cevapta başa dönüyor.
class ImageChallengeScreen extends StatefulWidget {
  const ImageChallengeScreen({super.key});

  @override
  State<ImageChallengeScreen> createState() => _ImageChallengeScreenState();
}

class _ChallengeQuestion {
  const _ChallengeQuestion(this.image, this.correct, this.options, this.level);

  final Uint8List image;
  final String correct;
  final List<String> options;
  final int level; // bulanıklık seviyesi, 1'den başlar
}

class _ImageChallengeScreenState extends State<ImageChallengeScreen> {
  final _random = Random();

  List<Champion> _champions = [];
  String? _error; // null değilse hata ekranı gösteriliyor

  late QuizRound _round;
  _ChallengeQuestion? _question; // null iken resim hazırlanıyor
  Future<_ChallengeQuestion>? _pending;
  String? _selected;
  bool _answered = false;

  bool _finished = false;
  bool _isNewBest = false;

  // Eskiden Future.delayed + setState vardı; ekrandan çıkınca hata veriyordu.
  Timer? _nextTimer;
  // Tekrar oyna'ya basılınca eski turdan gelen geç cevapları yok saymak için
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _round = QuizRound();
    _loadChampions();
  }

  @override
  void dispose() {
    _nextTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChampions() async {
    setState(() => _error = null);
    try {
      _champions = await DDragon.champions();
      if (!mounted) return;
      _startRound();
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Şampiyon listesi indirilemedi.');
    }
  }

  void _startRound() {
    _nextTimer?.cancel();
    _generation++;
    setState(() {
      _round = QuizRound();
      _finished = false;
      _isNewBest = false;
    });
    _loadQuestion(_buildQuestion(level: 1));
  }

  // Resim hazır olunca ekrana koyar, hata olursa tekrar dene ekranı çıkar
  Future<void> _loadQuestion(Future<_ChallengeQuestion> future) async {
    final generation = _generation;
    setState(() {
      _question = null;
      _selected = null;
      _answered = false;
      _error = null;
    });
    try {
      final question = await future;
      if (!mounted || generation != _generation) return;
      setState(() => _question = question);
    } catch (_) {
      // İndirme ya da resim işleme hatası; ikisinde de tekrar denemek yeterli
      if (!mounted || generation != _generation) return;
      setState(() => _error = 'Portreler indirilemedi.');
    }
  }

  Future<_ChallengeQuestion> _buildQuestion({required int level}) async {
    final first = _champions[_random.nextInt(_champions.length)];
    Champion second;
    do {
      second = _champions[_random.nextInt(_champions.length)];
    } while (second.id == first.id);

    final bytes = await Future.wait([DDragon.portrait(first), DDragon.portrait(second)]);
    // Ağır kısım: mobilde ayrı isolate'te çalışıyor
    final blended = await compute(blendPortraits, BlendJob(bytes[0], bytes[1], 4 + level * 2));

    final correct = _pairLabel(first, second);
    return _ChallengeQuestion(blended, correct, _buildOptions(first, second), level);
  }

  String _pairLabel(Champion a, Champion b) => '${a.name} - ${b.name}';

  // Şıklardan biri doğru ikiliden bir şampiyonu içeriyor, kalanlar rastgele.
  // "A - B" ile "B - A" aynı ikili sayılıyor, eskiden ikisi birden şıklarda çıkabiliyordu.
  List<String> _buildOptions(Champion first, Champion second) {
    final seen = <String>{_pairKey(first, second)};
    final options = [_pairLabel(first, second)];

    Champion pick() => _champions[_random.nextInt(_champions.length)];

    while (options.length < 4) {
      final a = options.length == 1 ? (_random.nextBool() ? first : second) : pick();
      final b = pick();
      if (a.id == b.id || !seen.add(_pairKey(a, b))) continue;
      options.add(_random.nextBool() ? _pairLabel(a, b) : _pairLabel(b, a));
    }
    return options..shuffle(_random);
  }

  String _pairKey(Champion a, Champion b) => ([a.id, b.id]..sort()).join('|');

  void _answer(String option) {
    final question = _question;
    if (_answered || question == null) return;

    final correct = option == question.correct;
    setState(() {
      _selected = option;
      _answered = true;
      _round.record(correct);
    });
    Sounds.answer(correct);

    // Kullanıcı cevabı görürken sıradaki resmi hazırlamaya başla
    if (!_round.isLastQuestion) {
      _pending = _buildQuestion(level: 1 + _round.streak);
      _pending!.ignore(); // hatayı _loadQuestion yakalıyor
    }

    _nextTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      if (_round.isLastQuestion) {
        final isNewBest = Storage.saveScore(GameMode.imageChallenge, _round.score);
        setState(() {
          _finished = true;
          _isNewBest = isNewBest;
        });
      } else {
        _round.next();
        _loadQuestion(_pending!);
      }
    });
  }

  void _retry() {
    if (_champions.isEmpty) {
      _loadChampions();
    } else {
      _loadQuestion(_buildQuestion(level: 1 + _round.streak));
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (_error != null) {
      body = _ErrorView(message: _error!, onRetry: _retry);
    } else if (_finished) {
      body = RoundResultView(
        round: _round,
        best: Storage.bestScore(GameMode.imageChallenge) ?? _round.score,
        isNewBest: _isNewBest,
        onReplay: _startRound,
      );
    } else {
      body = _buildGame();
    }

    return Scaffold(
      appBar: AppBar(title: Text(GameMode.imageChallenge.title)),
      body: body,
    );
  }

  Widget _buildGame() {
    final question = _question;
    return SafeArea(
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
                  Expanded(child: Center(child: _buildPicture(question))),
                  const QuestionTitle('Tahmin et: hangi ikili?'),
                  if (question != null)
                    AnswerList(
                      options: question.options,
                      correct: question.correct,
                      selected: _selected,
                      answered: _answered,
                      onSelect: _answer,
                    )
                  else
                    // Resim gelene kadar şıkların yerini koru, ekran zıplamasın
                    Column(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Container(
                            height: 54,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPicture(_ChallengeQuestion? question) {
    final borderColor = !_answered || question == null
        ? AppColors.goldDim
        : _selected == question.correct
            ? AppColors.correct
            : AppColors.wrong;

    return AspectRatio(
      aspectRatio: 1,
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
          child: question == null
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
                      SizedBox(height: 14),
                      Text('Portreler karıştırılıyor...', style: TextStyle(color: AppColors.muted)),
                    ],
                  ),
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(
                      question.image,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.medium,
                      gaplessPlayback: true,
                    ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.blur_on, size: 16, color: AppColors.gold),
                            const SizedBox(width: 4),
                            Text(
                              'Bulanıklık ${question.level}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.muted),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Bu mod resimleri Riot\'un sunucusundan çekiyor. İnternet bağlantını kontrol edip tekrar dene.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tekrar dene'),
            ),
          ],
        ),
      ),
    );
  }
}
