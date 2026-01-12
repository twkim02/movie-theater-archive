import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/record_store.dart';
import '../models/movie.dart';
import '../models/record.dart';
import '../theme/colors.dart';

void openAddRecordSheet(BuildContext context, Movie movie, {Record? initialRecord}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddRecordSheet(movie: movie, initialRecord: initialRecord),
  );
}

class _AddRecordSheet extends StatefulWidget {
  final Movie movie;
  final Record? initialRecord;
  const _AddRecordSheet({required this.movie, this.initialRecord});

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  DateTime watchDate = DateTime.now();
  double rating = 0.0;

  bool showRatingError = false;

  final TextEditingController oneLinerController = TextEditingController();
  final TextEditingController detailedController = TextEditingController();

  // ✅ 고정 태그
  final List<String> tags = ["혼자", "친구", "가족", "극장", "OTT"];
  // ✅ 선택/입력 태그가 모두 들어가는 최종 태그(최대 3개)
  final Set<String> selectedTags = {};

  // ✅ 해시태그 입력
  final TextEditingController _hashtagCtrl = TextEditingController();
  String? _hashtagError;

  // ✅ 사진 선택 상태
  final ImagePicker _picker = ImagePicker();
  final List<String> photoPaths = []; // 앱 내부로 복사된 로컬 경로들

  @override
  void initState() {
    super.initState();

    final r = widget.initialRecord;
    if (r != null) {
      watchDate = r.watchDate;
      rating = r.rating;
      oneLinerController.text = r.oneLiner ?? '';
      detailedController.text = r.detailedReview ?? '';
      selectedTags.addAll(r.tags);
      photoPaths.addAll(r.photoPaths);
    }
  }

  @override
  void dispose() {
    oneLinerController.dispose();
    detailedController.dispose();
    _hashtagCtrl.dispose();
    super.dispose();
  }

  String formatDate(DateTime d) {
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  TextStyle get labelStyle =>
      const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF777777));

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: watchDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => watchDate = picked);
    }
  }

  // ✅ 고정태그 선택 토글 (최대 3개 제한)
  void _toggleFixedTag(String t) {
    final on = selectedTags.contains(t);
    setState(() {
      if (on) {
        selectedTags.remove(t);
      } else {
        if (selectedTags.length >= 3) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("태그는 최대 3개까지 선택할 수 있어요")),
          );
          return;
        }
        selectedTags.add(t);
      }
      _hashtagError = null;
    });
  }

  // ✅ 해시태그 추가 (최대 3개 / 각 10자 제한)
  void _addHashtag() {
    final raw = _hashtagCtrl.text.trim();
    if (raw.isEmpty) return;

    final cleaned = raw.startsWith('#') ? raw.substring(1).trim() : raw;
    if (cleaned.isEmpty) return;

    if (cleaned.length > 10) {
      setState(() => _hashtagError = "글자수 초과(최대 10자)");
      return;
    }

    if (selectedTags.length >= 3) {
      setState(() => _hashtagError = "태그는 최대 3개까지 가능해요");
      return;
    }

    if (selectedTags.contains(cleaned)) {
      setState(() => _hashtagError = "이미 추가된 태그예요");
      return;
    }

    setState(() {
      selectedTags.add(cleaned);
      _hashtagCtrl.clear();
      _hashtagError = null;
    });
  }

  // ✅ 선택된 태그를 칩으로 보여주고, 탭하면 제거
  Widget _selectedTagChips() {
    if (selectedTags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: selectedTags.map((t) {
        return InkWell(
          onTap: () => setState(() => selectedTags.remove(t)),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE2F0),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFFF8FBF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.startsWith('#') ? t : '#$t',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: Color(0xFFFF4F9A),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.close, size: 14, color: Color(0xFFFF4F9A)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ✅ 갤러리에서 사진 선택 → 앱 폴더로 복사 저장 → photoPaths에 추가
  Future<void> _pickPhotos() async {
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final savedDir = Directory(p.join(dir.path, 'record_photos'));
    if (!await savedDir.exists()) {
      await savedDir.create(recursive: true);
    }

    final List<String> newPaths = [];
    for (final x in images) {
      final ext = p.extension(x.path);
      final fileName = 'photo_${DateTime.now().microsecondsSinceEpoch}$ext';
      final newPath = p.join(savedDir.path, fileName);
      await File(x.path).copy(newPath);
      newPaths.add(newPath);
    }

    setState(() => photoPaths.addAll(newPaths));
  }


  void _save() async {
    if (rating <= 0) {
      setState(() => showRatingError = true);
      return;
    }

    final isEdit = widget.initialRecord != null;

    if (isEdit) {
      final updated = widget.initialRecord!.copyWith(
        rating: rating,
        watchDate: watchDate,
        oneLiner: oneLinerController.text.trim(),
        detailedReview: detailedController.text.trim(),
        tags: selectedTags.toList(),
        photoPaths: photoPaths.toList(),
      );
      await RecordStore.update(updated); // ✅ await
    } else {
      final record = Record(
        id: RecordStore.nextId(),
        userId: 1,
        movie: widget.movie,
        rating: rating,
        watchDate: watchDate,
        oneLiner: oneLinerController.text.trim(),
        detailedReview: detailedController.text.trim(),
        tags: selectedTags.toList(),
        photoPaths: photoPaths.toList(),
      );
      await RecordStore.add(record); // ✅ await
    }

    if (!mounted) return;
    Navigator.pop(context);
  }




  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.initialRecord != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        isEdit ? "기록 수정" : "기록 추가",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // 본문(스크롤)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 영화 요약 카드
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFF0E3E8)),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                widget.movie.posterUrl,
                                width: 52,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 52,
                                  height: 70,
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.movie.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ✅ 1) 관람일
                      Text("관람일 *", style: labelStyle),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: pickDate,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0E3E8)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatDate(watchDate),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.black45),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ 2) 별점 라벨 + 빨간 에러 문구
                      Row(
                        children: [
                          Text("별점 * (0.5 단위)", style: labelStyle),
                          const SizedBox(width: 8),
                          if (showRatingError)
                            const Text(
                              "별점을 입력해주세요.",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _StarRatingFiveHalf(
                        value: rating,
                        onChanged: (v) => setState(() {
                          rating = v;
                          if (showRatingError) showRatingError = false;
                        }),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "현재 별점: ${rating.toStringAsFixed(1)}점",
                        style: TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w600),
                      ),

                      const SizedBox(height: 16),

                      // ✅ 3) 태그
                      Text("태그 (최대 3개)", style: labelStyle),
                      const SizedBox(height: 10),

                      // ✅ 선택된 태그(고정+입력) 표시 (눌러서 삭제 가능)
                      _selectedTagChips(),
                      if (selectedTags.isNotEmpty) const SizedBox(height: 12),

                      // ✅ 고정 태그 선택
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: tags.map((t) {
                          final on = selectedTags.contains(t);
                          return InkWell(
                            onTap: () => _toggleFixedTag(t),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: on ? const Color(0xFFFFE2F0) : Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: on ? const Color(0xFFFF8FBF) : const Color(0xFFE6E6E6),
                                ),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: on ? const Color(0xFFFF4F9A) : const Color(0xFF444444),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 12),

                      // ✅ 해시태그 입력 + 추가 버튼 (최대 10자)
                      Row(
                        children: [
                          Expanded(
                            child: _RoundedField(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              child: TextField(
                                controller: _hashtagCtrl,
                                maxLines: 1,
                                inputFormatters: [LengthLimitingTextInputFormatter(10)],
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: InputBorder.none,
                                  hintText: "#해시태그 입력 (최대 10자)",
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (_) {
                                  if (_hashtagError != null) setState(() => _hashtagError = null);
                                },
                                onSubmitted: (_) => _addHashtag(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _addHashtag,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                            child: const Text("추가", style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),

                      if (_hashtagError != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _hashtagError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // ✅ 4) 한줄평 (20자 제한)
                      Text("한줄평", style: labelStyle),
                      const SizedBox(height: 8),
                      _RoundedField(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        child: TextField(
                          controller: oneLinerController,
                          maxLines: 1,
                          inputFormatters: [LengthLimitingTextInputFormatter(20)],
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            counterText: "",
                            border: InputBorder.none,
                            hintText: "최대 20자 한줄평",
                            hintStyle: TextStyle(fontSize: 13),
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ✅ 5) 사진
                      Text("사진 (선택)", style: labelStyle),
                      const SizedBox(height: 8),
                      _UploadBox(onTap: _pickPhotos),

                      const SizedBox(height: 10),

                      if (photoPaths.isNotEmpty)
                        SizedBox(
                          height: 92,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photoPaths.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (_, i) {
                              final path = photoPaths[i];
                              return Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(path),
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: InkWell(
                                      onTap: () => setState(() => photoPaths.removeAt(i)),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0x99000000),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(Icons.close, size: 16, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ✅ 6) 후기(선택)
                      Text("후기 (선택)", style: labelStyle),
                      const SizedBox(height: 8),
                      _RoundedField(
                        child: TextField(
                          controller: detailedController,
                          maxLines: 5,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: "영화에 대한 자세한 후기를 작성해보세요",
                            hintStyle: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              // 하단 버튼
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          side: const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        child: const Text("취소", style: TextStyle(fontWeight: FontWeight.w800)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          backgroundColor: primaryColor,
                        ),
                        child: Text(
                          isEdit ? "수정 완료" : "저장",
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundedField extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const _RoundedField({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E3E8)),
      ),
      child: child,
    );
  }
}

class _UploadBox extends StatelessWidget {
  final VoidCallback onTap;
  const _UploadBox({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0E3E8)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, color: Color(0xFF999999)),
              SizedBox(width: 8),
              Text(
                "사진 추가하기",
                style: TextStyle(color: Color(0xFF999999), fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarRatingFiveHalf extends StatelessWidget {
  final double value; // 0.0 ~ 5.0, step 0.5
  final ValueChanged<double> onChanged;

  const _StarRatingFiveHalf({required this.value, required this.onChanged});

  IconData _iconForStar(int starIndex, double v) {
    final full = starIndex.toDouble();
    final half = starIndex - 0.5;

    if (v >= full) return Icons.star;
    if (v >= half) return Icons.star_half;
    return Icons.star_border;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final localX = details.localPosition.dx;
            final half = localX <= 14; // 반쪽 판정(원하면 12~16 조절)
            final newValue = half ? (idx - 0.5) : idx.toDouble();
            onChanged(newValue.clamp(0.0, 5.0));
          },
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              _iconForStar(idx, value),
              size: 28,
              color: (value >= (idx - 0.5)) ? const Color(0xFFFFC107) : Colors.black26,
            ),
          ),
        );
      }),
    );
  }
}
