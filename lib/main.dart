import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'data/record_store.dart';
import 'models/stored_record.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🟡 main() started');

  // ✅ 1. 커스텀 폰트 로딩 (기존 코드 유지)
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

  // ✅ 2. Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(StoredRecordAdapter());

  // ✅ 3. RecordStore 초기화 (Hive → 메모리 로드)
  await RecordStore.init();

  // ✅ 4. 앱 실행
  runApp(const MyApp());
}
