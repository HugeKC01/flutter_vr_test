import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vr_player/vr_player.dart';
import 'package:image_picker/image_picker.dart';
import 'vr_image_viewer.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: HomePage(),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final List<String> _links = [
    'https://cdn.bitmovin.com/content/assets/playhouse-vr/m3u8s/105560.m3u8',
  ];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      // Use raw file path for local playback
      final String filePath = video.path;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(videoUrl: filePath),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VR Player'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddLinkDialog,
          ),
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: _pickVideo,
            tooltip: 'Pick Video from Device',
          ),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VrImageViewer(),
                ),
              );
            },
            tooltip: 'Open VR Image Viewer',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _links.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_links[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPlayerPage(videoUrl: _links[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddLinkDialog() {
    final TextEditingController linkController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Link'),
          content: TextField(
            controller: linkController,
            decoration: const InputDecoration(hintText: 'Enter link'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _links.add(linkController.text);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerPage({super.key, required this.videoUrl});

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage>
    with TickerProviderStateMixin {
  late VrPlayerController _viewPlayerController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isShowingBar = false;
  bool _isPlaying = false;
  bool _isVideoFinished = false;
  bool _isLandScapeOrientation = false;
  bool _isVolumeSliderShown = false;
  bool _isVolumeEnabled = true;
  late double _playerWidth;
  late double _playerHeight;
  String? _duration;
  int? _intDuration;
  bool isVideoLoading = false;
  bool isVideoReady = false;
  String? _currentPosition;
  double _currentSliderValue = 0.1;
  double _seekPosition = 0.0;

  @override
  void initState() {
    // Lock orientation to landscape when opening video player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _toggleShowingBar();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Removed setState(() {}); to prevent UI freeze and ensure video time/seek bar stay in sync in fullscreen mode.
  }

  void _toggleShowingBar() {
    switchVolumeSliderDisplay(show: false);

    setState(() {
      _isShowingBar = !_isShowingBar;
      if (_isShowingBar) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _playerWidth = MediaQuery.of(context).size.width;
    _playerHeight = MediaQuery.of(context).size.height; // Use full body height
    _isLandScapeOrientation = MediaQuery.of(context).orientation == Orientation.landscape;

    // Hide system UI overlays (status bar and navigation bar)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      // Remove the appBar
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          // VrPlayer at the bottom
          SizedBox(
            width: _playerWidth,
            height: _playerHeight,
            child: VrPlayer(
              x: 0,
              y: 0,
              onCreated: onViewPlayerCreated,
              width: _playerWidth,
              height: _playerHeight,
            ),
          ),
          // Overlay a full-area GestureDetector above the player
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleShowingBar,
            ),
          ),
          if (_isShowingBar)
            Positioned(
              top: 32,
              left: 24,
              child: FadeTransition(
                opacity: _animation,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          if (_isShowingBar)
            Positioned(
              left: 24,
              right: 24,
              bottom: 32,
              child: FadeTransition(
                opacity: _animation,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(_isVideoFinished ? Icons.replay : _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        ),
                        onPressed: playAndPause,
                      ),
                      Text(
                        _currentPosition ?? '00:00:00',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: Colors.amberAccent,
                            inactiveTrackColor: Colors.grey,
                            trackHeight: 5,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
                            overlayColor: Colors.purple.withAlpha(32),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                          ),
                          child: Slider(
                            value: _seekPosition,
                            max: _intDuration?.toDouble() ?? 0.0,
                            onChangeEnd: (value) {
                              _viewPlayerController.seekTo(value.toInt());
                            },
                            onChanged: (value) {
                              onChangePosition(value.toInt());
                            },
                          ),
                        ),
                      ),
                      Text(
                        _duration ?? '00:00:00',
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_isLandScapeOrientation)
                        IconButton(
                          icon: Icon(_isVolumeEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: Colors.white,
                          ),
                          onPressed: () => switchVolumeSliderDisplay(show: true),
                        ),
                      IconButton(
                        icon: const Icon(Icons.vrpano, color: Colors.white),
                        onPressed: cardBoardPressed,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            height: 180,
            right: 4,
            top: MediaQuery.of(context).size.height / 4,
            child: _isVolumeSliderShown ? RotatedBox(quarterTurns: 3,
            child: Slider(
              value: _currentSliderValue,
              divisions: 10,
              onChanged: onChangeVolumeSlider,
            ),
            )
            : const SizedBox(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Restore orientation and system UI overlays when leaving video player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _animationController.dispose();
    super.dispose();
  }

  void cardBoardPressed() {
    _viewPlayerController.toggleVRMode();
  }

  Future<void> playAndPause() async {
    if (_isPlaying) {
      await _viewPlayerController.pause();
    } else {
      await _viewPlayerController.play();
    }

    setState(() {
      _isPlaying = !_isPlaying;
      _isVideoFinished = false;
    });
  }

  void onViewPlayerCreated(
    VrPlayerController controller,
    VrPlayerObserver observer,
  ) {
    _viewPlayerController = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      observer
        ..onStateChange = onRecieveState
        ..onDurationChange = onRecieveDuration
        ..onPositionChange = onChangePosition
        ..onFinishedChange = onRecieveEnded;
      // Add a small delay before loading the video to ensure everything is ready
      await Future.delayed(const Duration(milliseconds: 200));
      _viewPlayerController.loadVideo(
        videoUrl: widget.videoUrl,
      );
    });
  }

  void onRecieveState(VrState state) {
    switch (state) {
      case VrState.loading:
        setState(() {
          isVideoLoading = true;
        });
        break;
      case VrState.ready:
        setState(() {
          isVideoLoading = false;
          isVideoReady = true;
        });
        // Show the control bar only after video is ready
        if (!_isShowingBar) {
          _toggleShowingBar();
        }
        // Autoplay when video is ready
        if (!_isPlaying) {
          playAndPause();
        }
        break;
      case VrState.buffering:
      case VrState.idle:
        break;
    }
  }
  
  void onRecieveDuration(int millis) {
    setState(() {
      _intDuration = millis;
      _duration = millisecondsToDateTime(millis);
    });
  }

  void onChangePosition(int millis) {
    setState(() {
      _currentPosition = millisecondsToDateTime(millis);
      _seekPosition = millis.toDouble();
    });
  }

  void onRecieveEnded(bool isFinished) {
    setState(() {
      _isVideoFinished = isFinished;
    });
  }

  void onChangeVolumeSlider(double value) {
    _viewPlayerController.setVolume(value);
    setState(() {
      _isVolumeEnabled = value != 0.0;
      _currentSliderValue = value;
    });
  }

  void switchVolumeSliderDisplay({required bool show}) {
    setState(() {
      _isVolumeSliderShown = show;
    });
  }

  String millisecondsToDateTime(int milliseconds) => setDurationText(Duration(milliseconds: milliseconds));

  String setDurationText(Duration duration) {
    String twoDigits(int n) {
      if (n >= 10) return '$n';
      return '0$n';
    }

    final twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    final twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}

//https://cdn.bitmovin.com/content/assets/playhouse-vr/m3u8s/105560.m3u8