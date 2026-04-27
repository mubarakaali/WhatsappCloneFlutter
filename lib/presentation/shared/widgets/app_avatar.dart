import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double radius;

  const AppAvatar({super.key, required this.name, required this.photoUrl, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    final fallback = 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}';
    return CircleAvatar(radius: radius, backgroundImage: NetworkImage(photoUrl?.isNotEmpty == true ? photoUrl! : fallback));
  }
}
