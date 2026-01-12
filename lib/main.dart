import 'package:flutter/material.dart';
import 'app.dart';
import 'utils/env_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드 (TMDB API 키 등)
  try {
    await EnvLoader.load();
  } catch (e) {
    debugPrint('환경 변수 로드 실패: $e');
  }
  
  runApp(const MyApp());
}