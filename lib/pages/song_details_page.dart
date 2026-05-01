import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/song_details_view.dart';

class SongDetailsPage extends StatelessWidget {
  final Song song;
  const SongDetailsPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Song Details"),
      ),
      body: SongDetailsView(song: song),
    );
  }
}
