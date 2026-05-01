import 'package:flutter/material.dart';
import '../models/song.dart';

class SongDetailsView extends StatelessWidget {
  final Song song;
  const SongDetailsView({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Center(
            child: Card(
              margin: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  song.cover,
                  height: 220,
                  width: 220,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(song.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            song.artist,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text("Description", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                song.description,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text("More info", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(label: "Album", value: song.album),
                  _InfoRow(label: "Year", value: song.year.toString()),
                  _InfoRow(label: "Genre", value: song.genre),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text("Preview URL", style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                song.url,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.white70),
              ),
            ),
          ),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
              width: 70,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
              )),
          Expanded(
              child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
