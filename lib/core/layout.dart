import 'package:flutter/material.dart';

/// Shared breakpoints and overflow-safe layout helpers for phones like Pixel 9a.
class AppLayout {
  static const double compactWidth = 400;
  static const double stackButtonsBelow = 400;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth;

  static TextScaler clampedTextScaler(TextScaler scaler) =>
      scaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.15);

  static String dateLabel(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  static String stamp(DateTime dt) {
    final d = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  static double statsAspectRatio(double width) {
    if (width < 360) return 1.0;
    if (width < 420) return 1.08;
    return 1.25;
  }
}

/// Two (or more) actions that stay in a row on wide screens and stack on narrow ones.
class AdaptiveButtonRow extends StatelessWidget {
  const AdaptiveButtonRow({
    super.key,
    required this.children,
    this.gap = 8,
    this.stackBelow = AppLayout.stackButtonsBelow,
  });

  final List<Widget> children;
  final double gap;
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: gap),
                children[i],
              ],
            ],
          );
        }
        return Row(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Scales a single-line value down instead of overflowing its parent.
class FitValue extends StatelessWidget {
  const FitValue({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.end,
    this.alignment = Alignment.centerRight,
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
      ),
    );
  }
}
