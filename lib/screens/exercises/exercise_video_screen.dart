import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart' show AndroidWebViewController;

/// Tappable card showing a YouTube thumbnail for an exercise demo video.
class ExerciseVideoCard extends StatelessWidget {
  final String videoUrl;
  final String title;

  const ExerciseVideoCard({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  String? get _videoId {
    final uri = Uri.tryParse(videoUrl);
    return uri?.queryParameters['v'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final id = _videoId;
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: theme.colorScheme.surfaceContainerHighest,
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExerciseVideoScreen(
                  videoUrl: videoUrl,
                  title: title,
                ),
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (id != null)
                  Image.network(
                    'https://i.ytimg.com/vi/$id/hqdefault.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        _VideoPlaceholder(theme: theme),
                  )
                else
                  _VideoPlaceholder(theme: theme),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white70,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 10,
                  child: Row(
                    children: [
                      const Icon(Icons.smart_display_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Demo video — tap to watch',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_gymnastics_rounded,
          size: 72,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

/// Full-screen in-app player for an embedded YouTube demo video.
class ExerciseVideoScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const ExerciseVideoScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<ExerciseVideoScreen> createState() => _ExerciseVideoScreenState();
}

class _ExerciseVideoScreenState extends State<ExerciseVideoScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _loading = true),
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      );

    // Fixes YouTube player error 153 on Android: YouTube refuses to play in
    // the default WebView config (bot-like user agent + gesture-gated media).
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        controller.platform is AndroidWebViewController) {
      final androidController =
          controller.platform as AndroidWebViewController;
      androidController.setMediaPlaybackRequiresUserGesture(false);
      androidController.setUserAgent(
        'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      );
    }

    _controller = controller;
    _controller.loadHtmlString(_embedPage(), baseUrl: 'https://youtube.com');
  }

  /// Wraps the embed in an iframe inside a real document. Loading the embed
  /// URL directly as a top-level page makes YouTube throw player error 153;
  /// the iframe form is what YouTube's own embed/IFrame API expects.
  String _embedPage() {
    final uri = Uri.tryParse(widget.videoUrl);
    final id = uri?.queryParameters['v'];
    if (id == null) return widget.videoUrl;
    final embed = Uri(
      scheme: 'https',
      host: 'www.youtube.com',
      path: '/embed/$id',
      queryParameters: {
        'playsinline': '1',
        'rel': '0',
        'modestbranding': '1',
        'autoplay': '1',
        'mute': '1',
      },
    );
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  html, body { margin: 0; padding: 0; height: 100%; background: #000; overflow: hidden; }
  iframe { border: 0; width: 100%; height: 100%; display: block; }
</style>
</head>
<body>
<iframe src="$embed"
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"
  allowfullscreen referrerpolicy="origin"></iframe>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = (width * 9) / 16;
                return Center(
                  child: Container(
                    width: width,
                    height: height,
                    color: Colors.black,
                    child: WebViewWidget(controller: _controller),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}