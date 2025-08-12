import 'package:flutter/material.dart';
import 'package:wedding_app/features/dashboard/widgets/full_photo_viewer.dart';

class PhotoGrid extends StatelessWidget {
  final List<String> photos;

  const PhotoGrid({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final thumbUrl = "${photos[index]}?tr=w_300,h_300,c_fill";
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    FullPhotoViewer(imageUrls: photos, initialIndex: index),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              thumbUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
