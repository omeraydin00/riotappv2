import 'package:material_ui/material_ui.dart';

import 'character_hunt_screen.dart';
import 'game_mode.dart';
import 'image_challenge_screen.dart';
import 'image_guess_game.dart';
import 'image_guess_game2.dart';
import 'storage.dart';
import 'theme.dart';

// Ana menü: her mod için bir kart ve o modun en iyi skoru
class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  bool _soundOn = Storage.soundOn;

  Widget _screenFor(GameMode mode) => switch (mode) {
        GameMode.imageChallenge => const ImageChallengeScreen(),
        GameMode.characterHunt => const CharacterHuntScreen(),
        GameMode.imageGuess => const ImageGuessGame(),
        GameMode.imageGuess2 => const ImageGuessGame2(),
      };

  Future<void> _open(GameMode mode) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => _screenFor(mode)));
    // Dönünce yeni rekor varsa kartta görünsün
    if (mounted) setState(() {});
  }

  void _toggleSound() {
    setState(() => _soundOn = !_soundOn);
    Storage.soundOn = _soundOn;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          // Üstte hafif bir altın parıltı, gerisi düz lacivert
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.1,
            colors: [Color(0xFF1B2B4D), AppColors.background],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: _soundOn ? 'Sesi kapat' : 'Sesi aç',
                  onPressed: _toggleSound,
                  icon: Icon(
                    _soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Center(
                child: Image.asset('assets/images/lolquiz.png', width: 148, height: 148),
              ),
              const SizedBox(height: 12),
              const Text(
                'Şampiyonları ne kadar tanıyorsun?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.cream),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dört mod, her turda $questionsPerRound soru.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'MODLAR',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.gold,
                  ),
                ),
              ),
              for (final mode in GameMode.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ModeCard(
                    mode: mode,
                    best: Storage.bestScore(mode),
                    onTap: () => _open(mode),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.mode, required this.best, required this.onTap});

  final GameMode mode;
  final int? best;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.gold.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.goldDim),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.surfaceHigh, AppColors.background],
                  ),
                ),
                child: Icon(mode.icon, color: AppColors.gold, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mode.title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.cream),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      mode.description,
                      style: const TextStyle(fontSize: 13.5, color: AppColors.muted, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    _BestBadge(best: best),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: AppColors.goldDim),
            ],
          ),
        ),
      ),
    );
  }
}

class _BestBadge extends StatelessWidget {
  const _BestBadge({required this.best});

  final int? best;

  @override
  Widget build(BuildContext context) {
    final played = best != null;
    return Row(
      children: [
        Icon(
          played ? Icons.emoji_events_rounded : Icons.emoji_events_outlined,
          size: 15,
          color: played ? AppColors.gold : AppColors.muted,
        ),
        const SizedBox(width: 5),
        Text(
          played ? 'En iyi: $best/$questionsPerRound' : 'Henüz oynanmadı',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: played ? AppColors.gold : AppColors.muted,
          ),
        ),
      ],
    );
  }
}
