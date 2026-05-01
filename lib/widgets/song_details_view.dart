import 'package:flutter/material.dart';
import '../models/song.dart';

class SongDetailsView extends StatelessWidget {
  final Song song;
  const SongDetailsView({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(song.cover, height: 220, width: 220),
            ),
          ),
          const SizedBox(height: 16),
          Text(song.title,
              style: const TextStyle(color: Colors.white, fontSize: 22)),
          const SizedBox(height: 6),
          Text(song.artist,
              style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 16),
          const Text("Description",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          Text(song.description,
              style: const TextStyle(color: Colors.white70, height: 1.4)),
          const SizedBox(height: 18),
          const Text("More info",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          _InfoRow(label: "Album", value: song.album),
          _InfoRow(label: "Year", value: song.year.toString()),
          _InfoRow(label: "Genre", value: song.genre),
          const SizedBox(height: 18),
          const Text("Preview URL",
              style: TextStyle(color: Colors.white, fontSize: 18)),
          const SizedBox(height: 8),
          SelectableText(song.url,
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
              width: 70,
              child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.white))),
        ],
      ),
    );
  }
}