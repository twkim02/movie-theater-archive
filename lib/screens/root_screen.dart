import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'explore_screen.dart';
import 'diary_screen.dart';
import 'saved_screen.dart';
import 'taste_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int index = 0;

  // ✅ 여기만 핵심: List<Widget>로 타입 명시
  final List<Widget> screens = const [
    ExploreScreen(),
    DiaryScreen(),
    SavedScreen(),
    TasteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[index],
      bottomNavigationBar: _RectBottomBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
      ),
    );
  }
}

class _RectBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _RectBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double barHeight = 56;
    const Color selectedBg = Color(0xFFFFE2F0);
    const Color normalBg = Color(0xFFF7F3F7);
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: normalBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: barHeight,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                _RectTabItem(
                  selected: currentIndex == 0,
                  label: '탐색',
                  icon: Icons.explore_outlined,
                  selectedIcon: Icons.explore,
                  selectedBg: selectedBg,
                  onTap: () => onTap(0),
                ),
                _RectTabItem(
                  selected: currentIndex == 1,
                  label: '일기',
                  icon: Icons.book_outlined,
                  selectedIcon: Icons.book,
                  selectedBg: selectedBg,
                  onTap: () => onTap(1),
                ),
                _RectTabItem(
                  selected: currentIndex == 2,
                  label: '저장',
                  icon: Icons.bookmark_outline,
                  selectedIcon: Icons.bookmark,
                  selectedBg: selectedBg,
                  onTap: () => onTap(2),
                ),
                _RectTabItem(
                  selected: currentIndex == 3,
                  label: '취향',
                  icon: Icons.favorite_border,
                  selectedIcon: Icons.favorite,
                  selectedBg: selectedBg,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
          Row(
            children: List.generate(4, (i) {
              return Expanded(
                child: Container(
                  height: bottomInset,
                  color: currentIndex == i ? selectedBg : normalBg,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RectTabItem extends StatelessWidget {
  final bool selected;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Color selectedBg;
  final VoidCallback onTap;

  const _RectTabItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selectedBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? primaryColor : const Color(0xFF666666);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: selected ? selectedBg : Colors.transparent,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 2),
              Icon(selected ? selectedIcon : icon, color: fg, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
