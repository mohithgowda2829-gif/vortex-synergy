import 'package:flutter/material.dart';

class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    super.key,
    required this.children,
    this.maxColumns = 4,
    this.minTileWidth = 180,
    this.tileHeight = 144,
    this.spacing = 12,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minTileWidth;
  final double tileHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double maxWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : minTileWidth;
        final int calculatedColumns = ((maxWidth + spacing) / (minTileWidth + spacing)).floor();
        final int columns = calculatedColumns.clamp(1, maxColumns);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: tileHeight,
          ),
          itemBuilder: (BuildContext context, int index) => children[index],
        );
      },
    );
  }
}
