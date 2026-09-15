import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Abstract interface for playing audio instructions during Attention exercises.
abstract class AttentionAudioService {
  Future<void> playInstruction(String assetPath);
  Future<void> stop();
  void dispose();
}

/// Production implementation using the audioplayers plugin.
class DefaultAttentionAudioService implements AttentionAudioService {
  final AudioPlayer _player;

  DefaultAttentionAudioService({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  @override
  Future<void> playInstruction(String assetPath) async {
    try {
      await _player.stop();
      // AudioCache by default prefixes with 'assets/'.
      // If assetPath starts with 'assets/', strip it for AssetSource.
      final cleanPath = assetPath.startsWith('assets/')
          ? assetPath.substring('assets/'.length)
          : assetPath;
      await _player.play(AssetSource(cleanPath));
    } catch (e) {
      debugPrint('AttentionAudioService play error: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('AttentionAudioService stop error: $e');
    }
  }

  @override
  void dispose() {
    try {
      _player.dispose();
    } catch (e) {
      debugPrint('AttentionAudioService dispose error: $e');
    }
  }
}

/// Headless/Test implementation that avoids invoking native platform channels.
class NoOpAttentionAudioService implements AttentionAudioService {
  String? lastPlayedAsset;
  int playCount = 0;

  @override
  Future<void> playInstruction(String assetPath) async {
    lastPlayedAsset = assetPath;
    playCount++;
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}
