import 'package:material_ui/material_ui.dart';

import '../game_mode.dart';
import '../theme.dart';

// Oyun ekranlarının ortak parçaları: üst bilgi, cevap düğmesi, tur sonu ekranı

// Soru sayısı, skor ve seriyi gösteren üst kısım. Altındaki çubuk
// (Karakter Avı'nda süre, diğerlerinde soru ilerlemesi).
class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.round,
    required this.progress,
    this.progressColor,
    this.smooth = true,
  });

  final QuizRound round;
  final double progress;
  final Color? progressColor;
  // Süre çubuğu zaten her karede güncelleniyor, onda ek animasyona gerek yok
  final bool smooth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Soru ', style: TextStyle(color: AppColors.muted)),
                    TextSpan(
                      text: '${round.index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.cream),
                    ),
                    TextSpan(text: ' / ${round.total}', style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const Spacer(),
              _StatPill(
                icon: Icons.star_rounded,
                label: 'Skor',
                value: '${round.score}',
              ),
              const SizedBox(width: 8),
              _StatPill(
                icon: Icons.local_fire_department_rounded,
                label: 'Seri',
                value: '${round.streak}',
                highlight: round.streak >= 3,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress.clamp(0.0, 1.0)),
              duration: smooth ? const Duration(milliseconds: 250) : Duration.zero,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                color: progressColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.gold : AppColors.muted;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlight ? AppColors.goldDim : AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.cream),
          ),
        ],
      ),
    );
  }
}

// Cevap düğmesinin alabileceği durumlar
enum AnswerState { idle, correct, wrong, reveal, dimmed }

// Seçilen cevaba ve doğru cevaba göre bir seçeneğin durumunu bulur
AnswerState answerStateFor(String option, {String? selected, required String correct, bool answered = false}) {
  if (!answered) return AnswerState.idle;
  if (option == selected) {
    return option == correct ? AnswerState.correct : AnswerState.wrong;
  }
  if (option == correct) return AnswerState.reveal;
  return AnswerState.dimmed;
}

class AnswerButton extends StatelessWidget {
  const AnswerButton({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final AnswerState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color border, IconData? icon) = switch (state) {
      AnswerState.idle => (AppColors.surface, AppColors.border, null),
      AnswerState.correct => (AppColors.correct.withValues(alpha: 0.22), AppColors.correct, Icons.check_circle),
      AnswerState.wrong => (AppColors.wrong.withValues(alpha: 0.22), AppColors.wrong, Icons.cancel),
      AnswerState.reveal => (AppColors.surface, AppColors.correct, Icons.check_circle_outline),
      AnswerState.dimmed => (AppColors.surface, AppColors.border, null),
    };

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: state == AnswerState.dimmed ? 0.45 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: state == AnswerState.idle ? 1 : 1.6),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: state == AnswerState.idle ? onTap : null,
            borderRadius: BorderRadius.circular(14),
            splashColor: AppColors.gold.withValues(alpha: 0.12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cream,
                        ),
                      ),
                    ),
                    if (icon != null) Icon(icon, color: border, size: 22),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dört seçeneği alt alta dizer
class AnswerList extends StatelessWidget {
  const AnswerList({
    super.key,
    required this.options,
    required this.correct,
    required this.selected,
    required this.answered,
    required this.onSelect,
  });

  final List<String> options;
  final String correct;
  final String? selected;
  final bool answered;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnswerButton(
              label: option,
              state: answerStateFor(option, selected: selected, correct: correct, answered: answered),
              onTap: () => onSelect(option),
            ),
          ),
      ],
    );
  }
}

// Tur sonu ekranı
class RoundResultView extends StatelessWidget {
  const RoundResultView({
    super.key,
    required this.round,
    required this.best,
    required this.isNewBest,
    required this.onReplay,
  });

  final QuizRound round;
  final int best;
  final bool isNewBest;
  final VoidCallback onReplay;

  String get _message {
    final ratio = round.score / round.total;
    if (ratio == 1) return 'Kusursuz tur. Hepsini bildin!';
    if (ratio >= 0.7) return 'Çok iyi, şampiyonları tanıyorsun.';
    if (ratio >= 0.4) return 'Fena değil, bir tur daha?';
    return 'Isınma turu sayılır. Tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surface,
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 32),
                ],
              ),
              child: const Icon(Icons.emoji_events_rounded, size: 48, color: AppColors.gold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tur bitti',
              style: TextStyle(fontSize: 16, color: AppColors.muted, letterSpacing: 0.5),
            ),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${round.score}',
                    style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w800, color: AppColors.cream),
                  ),
                  TextSpan(
                    text: ' / ${round.total}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
            if (isNewBest) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold),
                ),
                child: const Text(
                  'Yeni rekor!',
                  style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 28),
            Row(
              children: [
                _ResultStat(label: 'En iyi skor', value: '$best/${round.total}'),
                const SizedBox(width: 12),
                _ResultStat(label: 'En uzun seri', value: '${round.bestStreak}'),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: onReplay,
              icon: const Icon(Icons.replay_rounded),
              label: const Text('Tekrar oyna'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Menüye dön'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

// Soru metni (ör. "Bu hangi şampiyon?")
class QuestionTitle extends StatelessWidget {
  const QuestionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 14),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.cream),
      ),
    );
  }
}
