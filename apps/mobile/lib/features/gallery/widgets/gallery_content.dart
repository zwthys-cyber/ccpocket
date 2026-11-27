import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/messages.dart';
import '../../../services/bridge_service.dart';
import 'gallery_filter_chips.dart';
import 'gallery_image_viewer.dart';
import 'gallery_tile.dart';

class GalleryContent extends StatefulWidget {
  final List<GalleryImage> images;
  final bool isSessionMode;
  final String httpBaseUrl;

  const GalleryContent({
    super.key,
    required this.images,
    required this.isSessionMode,
    required this.httpBaseUrl,
  });

  @override
  State<GalleryContent> createState() => _GalleryContentState();
}

class _GalleryContentState extends State<GalleryContent> {
  String? _selectedProject;
  bool _deleteInProgress = false;

  @override
  void didUpdateWidget(GalleryContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selectedProject != null &&
        !widget.images.any((img) => img.projectName == _selectedProject)) {
      _selectedProject = null;
    }
  }

  Map<String, int> _projectCounts() {
    final counts = <String, int>{};
    for (final img in widget.images) {
      counts[img.projectName] = (counts[img.projectName] ?? 0) + 1;
    }
    return counts;
  }

  List<GalleryImage> _filteredImages() {
    if (_selectedProject == null) return widget.images;
    return widget.images
        .where((img) => img.projectName == _selectedProject)
        .toList();
  }

  String _timeAgo(AppLocalizations l, String isoDate) {
    final date = DateTime.tryParse(isoDate)?.toLocal();
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l.justNow;
    if (diff.inMinutes < 60) return l.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.hoursAgo(diff.inHours);
    return l.daysAgo(diff.inDays);
  }

  void _openViewer(
    BuildContext context,
    List<GalleryImage> filtered,
    int index,
  ) {
    final bridge = context.read<BridgeService>();
    final baseUrl = widget.httpBaseUrl;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GalleryImageViewer(
          images: filtered,
          initialIndex: index,
          httpBaseUrl: baseUrl,
          onDelete: bridge.deleteGalleryImageWithResult,
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    GalleryImage image,
  ) async {
    if (_deleteInProgress) return;
    setState(() => _deleteInProgress = true);
    try {
      final confirmed = await showDeleteConfirmDialog(context);
      if (!confirmed || !context.mounted) return;
      final bridge = context.read<BridgeService>();
      final result = await bridge.deleteGalleryImageWithResult(image.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            galleryDeleteMessage(AppLocalizations.of(context), result),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _deleteInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final filtered = _filteredImages();
    final counts = _projectCounts();

    return Column(
      children: [
        if (!widget.isSessionMode && counts.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: GalleryFilterChips(
              projectCounts: counts,
              totalCount: widget.images.length,
              selectedProject: _selectedProject,
              onSelected: (p) => setState(() => _selectedProject = p),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 214,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.86,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final image = filtered[index];
              return GalleryTile(
                image: image,
                httpBaseUrl: widget.httpBaseUrl,
                timeAgo: _timeAgo(l, image.addedAt),
                onTap: _deleteInProgress
                    ? null
                    : () => _openViewer(context, filtered, index),
                onLongPress: _deleteInProgress
                    ? null
                    : () => _showDeleteDialog(context, image),
              );
            },
          ),
        ),
      ],
    );
  }
}
