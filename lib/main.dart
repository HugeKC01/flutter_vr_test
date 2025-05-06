import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vr_player/vr_player.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddLinkDialog,
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
  bool _isFullScreen = false;
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

  // Function to toggle the control bar in fullscreen mode
  void toggleControlBarInFullScreen() {
    if (_isFullScreen) {
      setState(() {
        _isShowingBar = !_isShowingBar;
        if (_isShowingBar) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _playerWidth = MediaQuery.of(context).size.width;
    _playerHeight = _isFullScreen ? MediaQuery.of(context).size.height : _playerWidth / 2;
    _isLandScapeOrientation = MediaQuery.of(context).orientation == Orientation.landscape;

    // Auto-hide control bar after a delay in fullscreen mode
    if (_isFullScreen && _isShowingBar) {
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _isFullScreen && _isShowingBar) {
          setState(() {
            _isShowingBar = false;
            _animationController.reverse();
          });
        }
      });
    }

    return Scaffold(
      appBar: _isFullScreen ? null : AppBar(
        title: const Text('VR Player'),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          // VrPlayer at the bottom
          VrPlayer(
            x: 0,
            y: 0,
            onCreated: onViewPlayerCreated,
            width: _playerWidth,
            height: _playerHeight,
          ),
          // Overlay a full-area GestureDetector above the player
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                // In fullscreen, toggle control bar on tap. Otherwise, only hide if showing.
                if (_isFullScreen) {
                  _toggleShowingBar();
                } else if (_isShowingBar) {
                  _toggleShowingBar();
                }
              },
            ),
          ),
          // Floating button for toggling control bar in fullscreen
          if (_isFullScreen)
            Positioned(
              top: 24,
              right: 24,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.black.withOpacity(0.5),
                child: Icon(
                  _isShowingBar ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
                onPressed: _toggleShowingBar,
                tooltip: 'Show/Hide Controls',
              ),
            ),
          if (_isShowingBar)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _animation,
                child: ColoredBox(
                  color: Colors.black,
                  child: Row(
                    children: <Widget>[
                      IconButton(
                        icon: Icon(_isVideoFinished ? Icons.replay : _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        ),
                        onPressed: playAndPause,
                      ),
                      Text(
                        _currentPosition ?? '00:00',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(       activeTrackColor: Colors.amberAccent,
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
                        _duration ?? '99:99',
                        style: const TextStyle(color: Colors.white),
                      ),
                      if (_isFullScreen || _isLandScapeOrientation)
                        IconButton(
                          icon: Icon(_isVolumeEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          color: Colors.white,
                          ),
                          onPressed: () => switchVolumeSliderDisplay(show: true),
                        ),
                        IconButton(
                          icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                          color: Colors.white,
                          ),
                          onPressed: fullScreenPressed,
                        ),
                        if (_isFullScreen)
                          IconButton(
                            icon: const Icon(Icons.vrpano, color: Colors.white),
                            onPressed: cardBoardPressed,
                          )
                          else
                            Container(),
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

  void cardBoardPressed() {
    _viewPlayerController.toggleVRMode();
  }

  Future<void> fullScreenPressed() async {
    try {
      // Toggle fullscreen mode in the player
      await _viewPlayerController.fullScreen();

      // Update fullscreen state
      setState(() {
        _isFullScreen = !_isFullScreen;
      });

      // Apply system UI and orientation changes based on fullscreen state
      if (_isFullScreen) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [],
        );
      } else {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight
        ]);
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        );
      }

      // Trigger a rebuild to ensure UI updates
      setState(() {});
    } catch (e) {
      debugPrint("Error toggling fullscreen mode: $e");
    }
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
    observer
      ..onStateChange = onRecieveState
      ..onDurationChange = onRecieveDuration
      ..onPositionChange = onChangePosition
      ..onFinishedChange = onRecieveEnded;
    _viewPlayerController.loadVideo(
      videoUrl: widget.videoUrl,
    );
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