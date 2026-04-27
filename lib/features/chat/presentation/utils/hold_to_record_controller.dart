import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Reusable controller for hold-to-record voice messages.
///
/// Keeps recording logic out of screen widgets to improve separation of concerns.
class HoldToRecordController {
  final AudioRecorder _recorder = AudioRecorder();
  DateTime? _recordingStartedAt;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> start({required String filePrefix}) async {
    if (_isRecording) return;
    if (!await _recorder.hasPermission()) return;
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: filePath,
    );
    _isRecording = true;
    _recordingStartedAt = DateTime.now();
  }

  Future<RecordedClip?> stop() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    final startedAt = _recordingStartedAt;
    _isRecording = false;
    _recordingStartedAt = null;
    if (path == null || startedAt == null) return null;
    return RecordedClip(
      file: File(path),
      durationMs: DateTime.now().difference(startedAt).inMilliseconds,
    );
  }

  Future<void> dispose() => _recorder.dispose();
}

class RecordedClip {
  final File file;
  final int durationMs;

  const RecordedClip({required this.file, required this.durationMs});
}
