import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {

  final AudioPlayer _player = AudioPlayer();

  Future<void> init() async {
    await _player.setAsset('assets/audio/song.mp3');

    _player.playbackEventStream.listen((event) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: _player.playing,
          processingState: AudioProcessingState.ready,
          controls: [
            MediaControl.play,
            MediaControl.pause,
          ],
        ),
      );
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
}