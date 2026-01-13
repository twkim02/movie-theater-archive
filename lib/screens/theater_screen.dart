import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // ✅ debugPrint
import 'package:geolocator/geolocator.dart';

import '../data/dummy_theaters.dart';
import '../models/theater.dart';
import '../widgets/theater_card.dart';
import '../models/movie.dart';

class TheaterScreen extends StatefulWidget {
  final Movie movie; // ✅ 어떤 영화의 영화관 보기인지

  const TheaterScreen({
    super.key,
    required this.movie,
  });

  @override
  State<TheaterScreen> createState() => _TheaterScreenState();
}

class _TheaterScreenState extends State<TheaterScreen> {
  bool loading = false;
  String? error;

  DateTime selectedDate = DateTime.now();
  List<Theater> theaters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<Position> _getPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw Exception('위치 서비스가 꺼져 있어요. 설정에서 켜주세요.');

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) throw Exception('위치 권한이 거부되었어요.');
    if (perm == LocationPermission.deniedForever) {
      throw Exception('위치 권한이 영구 거부 상태예요. 설정에서 허용해주세요.');
    }

    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final pos = await _getPosition();

      // ✅ (로그1) 현재 좌표 확인
      debugPrint('📍 current pos: ${pos.latitude}, ${pos.longitude}');

      final list = await fetchNearbyTheatersReal(
        lat: pos.latitude,
        lng: pos.longitude,
        date: selectedDate,
        movieTitle: widget.movie.title,
      );

      // ✅ (로그2) 받아온 극장 개수 확인
      debugPrint('🎬 theaters count: ${list.length}');

      setState(() => theaters = list);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText =
        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.movie.title} · 영화관 보기'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(dateText),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('내 위치'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : (error != null)
                    ? _ErrorView(message: error!, onRetry: _load)
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: theaters.length,
                        itemBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TheaterCard(t: theaters[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      ),
    );
  }
}
