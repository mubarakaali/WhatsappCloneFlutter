import 'package:flutter/material.dart';

import '../../../../domain/entities/status_item.dart';

class StatusViewerScreen extends StatelessWidget {
  final String ownerName;
  final String? ownerPhotoUrl;
  final List<StatusItem> statuses;

  const StatusViewerScreen({
    super.key,
    required this.ownerName,
    required this.ownerPhotoUrl,
    required this.statuses,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(ownerName),
      ),
      body: PageView.builder(
        itemCount: statuses.length,
        itemBuilder: (context, index) {
          final item = statuses[index];
          if (item.type == StatusType.image && (item.imageUrl?.isNotEmpty ?? false)) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.network(item.imageUrl!, fit: BoxFit.contain),
                if (item.text.isNotEmpty)
                  Positioned(
                    bottom: 24,
                    left: 16,
                    right: 16,
                    child: Text(
                      item.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
              ],
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                item.text,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          );
        },
      ),
    );
  }
}
