import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/reader/reader_rendering.dart';

/// Safe local EPUB image surface. Remote URLs and unsupported formats never
/// reach this widget; the importer only persists managed image assets.
class ReaderEpubImage extends StatelessWidget {
  const ReaderEpubImage({
    super.key,
    required this.placement,
    required this.file,
    this.maxHeight,
  });

  final ReaderImagePlacement placement;
  final File file;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final resolvedMaxHeight =
        maxHeight ?? MediaQuery.sizeOf(context).height * .42;
    final child = Image.file(
      file,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          placement.altText?.trim().isNotEmpty == true
          ? Text(
              placement.altText!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            )
          : const SizedBox.shrink(),
    );
    final ratio =
        placement.width != null &&
            placement.height != null &&
            placement.width! > 0 &&
            placement.height! > 0
        ? placement.width! / placement.height!
        : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: math.max(0, resolvedMaxHeight)),
        child: ratio == null
            ? child
            : AspectRatio(aspectRatio: ratio, child: child),
      ),
    );
  }
}

/// Returns the largest height that can be assigned to each image in a paged
/// image area without exceeding its available height. The spacing belongs to
/// the image widget itself, so it is reserved before dividing the remaining
/// space. This is deliberately a presentation-only calculation: images stay
/// sidecar data and do not affect UTF-16 offsets or pagination.
double pagedEpubImageMaxHeight({
  required double availableHeight,
  required int imageCount,
  double spacing = 12,
}) {
  if (availableHeight <= 0 || imageCount <= 0) return 0;
  final reservedSpacing = spacing * imageCount;
  return math.max(0, (availableHeight - reservedSpacing) / imageCount);
}
