import 'package:flutter/foundation.dart';
import '../models/record.dart';

/// @deprecated 이 클래스는 더 이상 사용되지 않습니다.
/// DB 마이그레이션으로 인해 AppState와 RecordRepository를 사용하세요.
/// 
/// 대체 방법:
/// - `AppState.addRecord(Record)` - 기록 추가
/// - `AppState.records` - 기록 목록 조회
/// - `RecordRepository` - 직접 DB 접근이 필요한 경우
@Deprecated('Use AppState and RecordRepository instead')
class RecordStore {
  // 앱 전체에서 공유되는 기록 리스트
  static final ValueNotifier<List<Record>> records = ValueNotifier<List<Record>>([]);

  static int _nextId = 1;

  static int nextId() => _nextId++;

  static void add(Record record) {
    final current = List<Record>.from(records.value);
    current.insert(0, record); // 최신이 위로 오게
    records.value = current;
  }
}
