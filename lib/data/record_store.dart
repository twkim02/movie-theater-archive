import 'package:flutter/foundation.dart';
import '../models/record.dart';

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
