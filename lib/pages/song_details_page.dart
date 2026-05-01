import 'package:flutter/material.dart';
import '../models/song.dart';
import '../widgets/song_details_view.dart';

class SongDetailsPage extends StatelessWidget {
  final Song song;
  const SongDetailsPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title:
            const Text("Song Details", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SongDetailsView(song: song),
    );
  }
}