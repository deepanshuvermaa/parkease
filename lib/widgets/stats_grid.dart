import 'package:flutter/material.dart';
import 'stats_card.dart';

class StatsGrid extends StatelessWidget {
  final List<StatsItem> items;
  final int crossAxisCount;

  const StatsGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return StatsCard(
          title: item.title,
          value: item.value,
          icon: item.icon,
          color: item.color,
          subtitle: item.subtitle,
          onTap: item.onTap,
        );
      },
    );
  }
}

class StatsItem {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;
  final VoidCallback? onTap;

  StatsItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
    this.onTap,
  });
}