import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MusicManager extends ChangeNotifier {
  String _currentTitle = 'NO LINK';
  String _currentArtist = 'Connect Device';
  String? _artworkUrl;
  bool _isPlaying = false;

  String get currentTitle => _currentTitle;
  String get currentArtist => _currentArtist;
  String? get artworkUrl => _artworkUrl;
  bool get isPlaying => _isPlaying;

  Future<void> playSearch(String query) async {
    if (query.isEmpty) return;

    try {
      final intent = AndroidIntent(
        action: 'android.media.action.MEDIA_PLAY_FROM_SEARCH',
        arguments: <String, dynamic>{
          'query': query,
        },
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );

      await intent.launch();

      await Future.delayed(const Duration(seconds: 2));
      _updateCurrentTrack(query);
    } catch (e) {
      debugPrint('Failed to launch music intent: $e');
    }
  }

  Future<void> addToQueue(String query) async {
    if (query.isEmpty) return;

    try {
      final intent = AndroidIntent(
        action: 'android.media.action.ADD_TO_PLAYLIST',
        arguments: <String, dynamic>{
          'query': query,
        },
      );

      await intent.launch();
    } catch (e) {
      debugPrint('Failed to add to queue: $e');
    }
  }

  Future<void> sendMediaControl(String action) async {
    try {
      int keyCode;
      switch (action) {
        case 'play':
        case 'pause':
        case 'playpause':
          keyCode = 85;
          break;
        case 'next':
          keyCode = 87;
          break;
        case 'prev':
          keyCode = 88;
          break;
        default:
          return;
      }

      final intent = AndroidIntent(
        action: 'android.intent.action.MEDIA_BUTTON',
        arguments: <String, dynamic>{
          'android.intent.extra.KEY_EVENT': keyCode,
        },
      );

      await intent.launch();
    } catch (e) {
      debugPrint('Failed to send media control: $e');
    }
  }

  Future<void> _updateCurrentTrack(String searchQuery) async {
    _currentTitle = searchQuery;
    _currentArtist = 'Searching...';
    _isPlaying = true;
    notifyListeners();

    await _fetchArtwork(searchQuery);
  }

  Future<void> _fetchArtwork(String query) async {
    try {
      final itunesUrl = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(query)}&entity=song&limit=1',
      );

      final response = await http.get(itunesUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final result = data['results'][0];
          _artworkUrl = result['artworkUrl100'];
          _currentArtist = result['artistName'] ?? 'Unknown Artist';
          _currentTitle = result['trackName'] ?? query;
          notifyListeners();
          return;
        }
      }

      await _fetchYouTubeThumbnail(query);
    } catch (e) {
      debugPrint('Failed to fetch iTunes artwork: $e');
      await _fetchYouTubeThumbnail(query);
    }
  }

  Future<void> _fetchYouTubeThumbnail(String query) async {
    try {
      const ytKey = 'AIzaSyB65Eig7UCAkmHf--6YhvGqZXCx7YxTNX0';
      final ytUrl = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search?part=snippet&q=${Uri.encodeComponent(query)}&type=video&maxResults=1&key=$ytKey',
      );

      final response = await http.get(ytUrl);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] != null && (data['items'] as List).isNotEmpty) {
          final item = data['items'][0];
          _artworkUrl = item['snippet']['thumbnails']['high']['url'];
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch YouTube thumbnail: $e');
    }
  }

  void updateTrackInfo(String title, String artist, bool playing) {
    _currentTitle = title;
    _currentArtist = artist;
    _isPlaying = playing;
    _artworkUrl = null;
    notifyListeners();

    if (playing && title.isNotEmpty) {
      _fetchArtwork('$artist $title');
    }
  }

  void reset() {
    _currentTitle = 'NO LINK';
    _currentArtist = 'Connect Device';
    _artworkUrl = null;
    _isPlaying = false;
    notifyListeners();
  }
}
