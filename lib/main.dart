import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🟡 main() started');

  try {
    final data = await rootBundle.load('assets/fonts/Typo_Crayon B.ttf');
    print('🟢 asset bytes = ${data.lengthInBytes}');

    final loader = FontLoader('TypoCrayon');
    loader.addFont(Future.value(data));
    await loader.load();

    print('✅ TypoCrayon font loaded!');
  } catch (e, st) {
    print('❌ Font load failed: $e');
    print(st);
  }

  runApp(const MyApp());
}
