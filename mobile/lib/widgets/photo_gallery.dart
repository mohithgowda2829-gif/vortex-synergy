import 'package:flutter/material.dart';

import '../config/app_config.dart';

class PhotoGallery extends StatelessWidget {
  const PhotoGallery({
    super.key,
    required this.photoUrls,
    this.height = 180,
  });

  final List<String> photoUrls;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (photoUrls.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.photo_library_outlined),
              SizedBox(height: 8),
              Text('No photos added'),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photoUrls.length,
        separatorBuilder: (BuildContext context, int index) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              AppConfig.resolveUrl(photoUrls[index]),
              width: height * 1.25,
              height: height,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                return Container(
                  width: height * 1.25,
                  height: height,
                  color: const Color(0xFFE5E7EB),
                  child: const Center(child: Icon(Icons.broken_image_outlined)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
