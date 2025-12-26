import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bananatalk_app/service/endpoints.dart';
import 'package:bananatalk_app/providers/provider_models/message_model.dart';

class VoiceMessageService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _getHeaders(String? token) {
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get the temporary directory for voice recordings
  static Future<String> getRecordingDirectory() async {
    final directory = await getTemporaryDirectory();
    final recordingDir = Directory('${directory.path}/voice_recordings');
    if (!await recordingDir.exists()) {
      await recordingDir.create(recursive: true);
    }
    return recordingDir.path;
  }

  /// Generate a unique filename for a new recording
  static Future<String> generateRecordingPath() async {
    final dir = await getRecordingDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$dir/voice_$timestamp.m4a';
  }

  /// Upload a voice message and send it to a user
  static Future<Map<String, dynamic>> sendVoiceMessage({
    required String receiverId,
    required File voiceFile,
    required int durationSeconds,
    List<double>? waveform,
  }) async {
    try {
      final token = await _getToken();
      final url = Uri.parse('${Endpoints.baseURL}${Endpoints.voiceMessageURL}');

      final request = http.MultipartRequest('POST', url);
      request.headers.addAll(_getHeaders(token));

      // Add the voice file
      final mimeType = _getMimeType(voiceFile.path);
      request.files.add(
        await http.MultipartFile.fromPath(
          'voice',
          voiceFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      // Add other fields
      request.fields['receiver'] = receiverId;
      request.fields['duration'] = durationSeconds.toString();
      
      if (waveform != null && waveform.isNotEmpty) {
        request.fields['waveform'] = jsonEncode(waveform);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] != null ? Message.fromJson(data['data']) : null,
          'message': data['message'] ?? 'Voice message sent',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to send voice message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Get MIME type based on file extension
  static String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'm4a':
        return 'audio/m4a';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      default:
        return 'audio/m4a';
    }
  }

  /// Clean up old voice recordings to save space
  static Future<void> cleanupOldRecordings({int maxAgeDays = 7}) async {
    try {
      final dir = await getRecordingDirectory();
      final directory = Directory(dir);
      
      if (!await directory.exists()) return;
      
      final now = DateTime.now();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final age = now.difference(stat.modified);
          if (age.inDays > maxAgeDays) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      print('Error cleaning up old recordings: $e');
    }
  }

  /// Download a voice message for offline playback
  static Future<File?> downloadVoiceMessage({
    required String url,
    required String messageId,
  }) async {
    try {
      final dir = await getRecordingDirectory();
      final localPath = '$dir/downloaded_$messageId.m4a';
      final localFile = File(localPath);
      
      // Check if already downloaded
      if (await localFile.exists()) {
        return localFile;
      }
      
      // Download the file
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        await localFile.writeAsBytes(response.bodyBytes);
        return localFile;
      }
      
      return null;
    } catch (e) {
      print('Error downloading voice message: $e');
      return null;
    }
  }

  /// Notify server that voice message was played
  static Future<void> notifyVoiceMessagePlayed({
    required String messageId,
    required String senderId,
  }) async {
    // This would emit a socket event - handled in chat_single.dart
    // socket.emit('voiceMessagePlayed', { messageId, senderId })
  }

  /// Generate waveform data from audio samples
  static List<double> generateWaveformFromSamples(List<double> samples, int targetLength) {
    if (samples.isEmpty) {
      return List.filled(targetLength, 0.1);
    }

    if (samples.length <= targetLength) {
      // Pad with zeros if too short
      return [...samples, ...List.filled(targetLength - samples.length, 0.1)];
    }

    // Downsample to target length
    final step = samples.length / targetLength;
    final result = <double>[];

    for (int i = 0; i < targetLength; i++) {
      final start = (i * step).floor();
      final end = ((i + 1) * step).floor().clamp(0, samples.length);
      
      if (start >= end) {
        result.add(0.1);
        continue;
      }

      // Get max amplitude in this segment
      double maxAmplitude = 0.0;
      for (int j = start; j < end; j++) {
        final amplitude = samples[j].abs();
        if (amplitude > maxAmplitude) {
          maxAmplitude = amplitude;
        }
      }

      // Normalize to 0-1 range
      result.add(maxAmplitude.clamp(0.0, 1.0));
    }

    return result;
  }

  /// Format duration in seconds to mm:ss string
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Parse duration string (mm:ss) to seconds
  static int parseDuration(String duration) {
    final parts = duration.split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return minutes * 60 + seconds;
    }
    return 0;
  }
}

/// State for voice recording
class VoiceRecordingState {
  final bool isRecording;
  final bool isPaused;
  final Duration duration;
  final String? filePath;
  final List<double> amplitudes;
  final String? error;

  const VoiceRecordingState({
    this.isRecording = false,
    this.isPaused = false,
    this.duration = Duration.zero,
    this.filePath,
    this.amplitudes = const [],
    this.error,
  });

  VoiceRecordingState copyWith({
    bool? isRecording,
    bool? isPaused,
    Duration? duration,
    String? filePath,
    List<double>? amplitudes,
    String? error,
  }) {
    return VoiceRecordingState(
      isRecording: isRecording ?? this.isRecording,
      isPaused: isPaused ?? this.isPaused,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      amplitudes: amplitudes ?? this.amplitudes,
      error: error,
    );
  }
}

/// State for voice playback
class VoicePlaybackState {
  final bool isPlaying;
  final bool isLoading;
  final Duration position;
  final Duration duration;
  final String? error;

  const VoicePlaybackState({
    this.isPlaying = false,
    this.isLoading = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.error,
  });

  VoicePlaybackState copyWith({
    bool? isPlaying,
    bool? isLoading,
    Duration? position,
    Duration? duration,
    String? error,
  }) {
    return VoicePlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      error: error,
    );
  }

  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return position.inMilliseconds / duration.inMilliseconds;
  }
}

