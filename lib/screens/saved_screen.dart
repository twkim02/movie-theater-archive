import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/colors.dart';
import '../models/movie.dart';
import '../state/app_state.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Movie> _filterMovies(List<Movie> movies) {
    final q = _query.trim();
    if (q.isEmpty) return movies;
    return movies.where((m) => m.title.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<AppState>(
        builder: (context, appState, _) {
          final savedMovies = appState.wishlist.map((e) => e.movie).toList();
          final shown = _filterMovies(savedMovies);

          final bubbleText =
              "찜해둔 영화는 ${savedMovies.length}편!\n오늘은 어떤 영화를 볼까요?";

          // ✅ 검색/카드 “조금만” 오른쪽 이동 (원래 0.84 컨테이너 안에서 추가로 밀기)
          const double contentShiftRight = 20; // 더 원하면 12~14

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/notebook_page.png',
                  fit: BoxFit.cover,
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  child: Column(
                    children: [
                      // ✅ 상단: 캐릭터는 그대로, 말풍선만 "작게" + 글자 중앙정렬
                      SizedBox(
                        height: 86,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              left: 330,
                              top: 0,
                              child: Transform.rotate(
                                angle: -0.06,
                                child: Image.asset(
                                  'assets/happy_character.png',
                                  width: 120,
                                ),
                              ),
                            ),

                            // ✅ 말풍선: 훨씬 작은 크기로
                            Positioned(
                              left: 20,
                              top: -14,
                              child: _SmallBubblePng(
                                assetPath: 'assets/bubble_long.png',
                                text: bubbleText,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ✅ 노트 "안" 영역
                      Expanded(
                        child: Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
                            child: Column(
                              children: [
                                // ✅ 검색창/카드들을 조금 오른쪽으로
                                Padding(
                                  padding: const EdgeInsets.only(left: contentShiftRight),
                                  child: _SearchBar(
                                    controller: _searchController,
                                    onChanged: (v) => setState(() => _query = v),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                Expanded(
                                  child: (savedMovies.isEmpty)
                                      ? Center(
                                          child: Text(
                                            "아직 저장한 영화가 없어요.",
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      : (shown.isEmpty)
                                          ? Center(
                                              child: Text(
                                                "검색 결과가 없어요.",
                                                style: TextStyle(
                                                  color: textSecondary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          : Padding(
                                              padding: const EdgeInsets.only(left: contentShiftRight),
                                              child: GridView.builder(
                                                itemCount: shown.length,
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 3,
                                                  crossAxisSpacing: 10,
                                                  mainAxisSpacing: 12,
                                                  childAspectRatio: 0.74,
                                                ),
                                                itemBuilder: (context, index) {
                                                  final m = shown[index];
                                                  return _SavedSimpleCard(
                                                    movie: m,
                                                    onRemove: () => appState.removeFromWishlist(m.id),
                                                  );
                                                },
                                              ),
                                            ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ✅ "작은" 말풍선 PNG + 텍스트 중앙정렬
class _SmallBubblePng extends StatelessWidget {
  final String assetPath;
  final String text;

  const _SmallBubblePng({
    required this.assetPath,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ 말풍선 사이즈를 확 줄임
    // 너 스샷 기준: 가로 250~280 / 세로 64~72 정도가 귀여움
    return SizedBox(
      width: 320,
      height: 92,
      child: Stack(
        children: [
          Image.asset(
            assetPath,
            width: 320,
            height: 92,
            fit: BoxFit.fill, // ✅ 작게 줄일 때 비율 유지보다 fill이 더 "풍선" 느낌 잘 나옴
          ),

          // ✅ 글자: 중간 정렬(가로+세로)
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(26, 4, 18, 10),
              child: Center(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.6,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    color: Color(0xFF3A2E2E),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ 검색창 (아이콘 1개)
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EE).withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                hintText: "저장한 영화 검색 (제목)",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _SavedSimpleCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onRemove;

  const _SavedSimpleCard({
    required this.movie,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ 포스터 크게
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        movie.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ),
                // ✅ 제목 한 줄
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                  child: Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3A2E2E),
                    ),
                  ),
                ),
              ],
            ),

            // 북마크 버튼
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                  child: const Icon(Icons.bookmark, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _StarsDisplay extends StatelessWidget {
  final double value;
  const _StarsDisplay({required this.value});

  IconData _iconFor(int idx) {
    final full = idx.toDouble();
    final half = idx - 0.5;
    if (value >= full) return Icons.star;
    if (value >= half) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        final idx = i + 1;
        final icon = _iconFor(idx);
        final filled = icon != Icons.star_border;

        return Icon(
          icon,
          size: 14,
          color: filled ? const Color(0xFFFFC107) : Colors.black26,
        );
      }),
    );
  }
}
