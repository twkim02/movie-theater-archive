import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../data/saved_store.dart';
import '../models/movie.dart';
import '../data/dummy_movies.dart';

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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          '무비어리',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<Set<String>>(
          valueListenable: SavedStore.savedIds,
          builder: (context, savedIds, _) {
            final allMoviesList = DummyMovies.getMovies();
            final savedMovies = allMoviesList.where((m) => savedIds.contains(m.id)).toList();
            final shown = _filterMovies(savedMovies);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Text(
                  "저장",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "나중에 볼 영화",
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 10),

                // 검색창
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      isDense: true,
                      icon: Icon(Icons.search, size: 20),
                      hintText: "저장한 영화 검색 (제목)",
                      border: InputBorder.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (savedMovies.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        "아직 저장한 영화가 없어요.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else if (shown.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Text(
                        "검색 결과가 없어요.",
                        style: TextStyle(
                          color: textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: shown.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.74,
                    ),
                    itemBuilder: (context, index) {
                      final m = shown[index];
                      return _SavedGridCard(movie: m);
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SavedGridCard extends StatelessWidget {
  final Movie movie;
  const _SavedGridCard({required this.movie});

  @override
  Widget build(BuildContext context) {
    const radius = 8.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0xFFEDEDED)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _StarsDisplay(value: movie.voteAverage),
                  const SizedBox(height: 4),
                  Text(
                    movie.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        movie.posterUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 북마크 해제
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: () => SavedStore.toggle(movie.id),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
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
