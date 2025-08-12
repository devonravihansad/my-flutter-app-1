import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class FullPhotoViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullPhotoViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: PhotoViewGallery.builder(
        itemCount: imageUrls.length,
        pageController: PageController(initialPage: initialIndex),
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(
              "${imageUrls[index]}?tr=w_1200,h_1200,q_auto",
            ),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2.5,
          );
        },
        loadingBuilder: (context, _) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
    );
  }
}
