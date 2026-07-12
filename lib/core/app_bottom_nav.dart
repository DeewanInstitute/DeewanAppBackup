import 'package:flutter/material.dart';
import 'package:deewan_institute_app/core/app_colors.dart';
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  // static const _orange = Color(0xFFFF7327);

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.search_rounded, 'Dictionary'),
    (Icons.access_time_outlined, 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(50, 0, 50, 22 + bottomPadding),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withValues(alpha: 0.26),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final active = currentIndex == index;

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () => onTap(index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.$1,
                      color: Colors.white,
                      size: active ? 27 : 25,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.$2,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: active ? 1 : 0.72,
                        ),
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
