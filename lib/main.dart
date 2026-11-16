import 'package:material_ui/material_ui.dart';

import 'main_menu.dart';
import 'storage.dart';
import 'theme.dart';

// Uygulamanın tek giriş noktası
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init(); // en iyi skorlar ve ses ayarı
  runApp(const RiotQuizApp());
}

class RiotQuizApp extends StatelessWidget {
  const RiotQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoL Quiz',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const MainMenu(),
    );
  }
}
