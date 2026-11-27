import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';

import '../../../models/messages.dart';

const _kCacheMaxAge = Duration(days: 7);

class GalleryTile extends StatelessWidget {
  final GalleryImage image;
  final String httpBaseUrl;
  final String timeAgo;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GalleryTile({
    super.key,
    required this.image,
    required this.httpBaseUrl,
    required this.timeAgo,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final imageUrl = '$httpBaseUrl${image.url}';

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('gallery_tile_${image.id}'),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Hero(
                tag: 'gallery_${image.id}',
                child: ColoredBox(
                  color: colors.surfaceContainer,
                  child: SizedBox(
                    width: double.infinity,
                    child: ExtendedImage.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      cache: true,
                      cacheMaxAge: _kCacheMaxAge,
                      loadStateChanged: (state) {
                        switch (state.extendedImageLoadState) {
                          case LoadState.loading:
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          case LoadState.completed:
                            return state.completedWidget;
                          case LoadState.failed:
                            return const Center(
                              child: Icon(Icons.broken_image, size: 32),
                            );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 2, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          image.projectName,
                          style: theme.textTheme.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (timeAgo.isNotEmpty)
                          Text(timeAgo, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (onLongPress != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      tooltip: MaterialLocalizations.of(context).deleteButtonTooltip,
                      color: colors.onSurfaceVariant,
                      onPressed: onLongPress,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
