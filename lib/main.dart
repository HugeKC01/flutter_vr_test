import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vr_player/vr_player.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vr_image_viewer.dart';
import 'theme.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('theme_mode');
    setState(() {
      if (mode == 'light') {
        _themeMode = ThemeMode.light;
      } else if (mode == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.system;
      }
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = mode;
    });
    await prefs.setString('theme_mode', mode.name);
  }

  @override
  Widget build(BuildContext context) {
    final materialTheme = MaterialTheme(ThemeData.light().textTheme);
    final lightScheme = MaterialTheme.lightScheme();
    final darkScheme = MaterialTheme.darkScheme();
    
    return MaterialApp(
      theme: materialTheme.light().copyWith(
        primaryColor: lightScheme.primary,
      ),
      darkTheme: materialTheme.dark().copyWith(
        primaryColor: darkScheme.primary,
      ),
      themeMode: _themeMode,
      home: HomePage(
        themeMode: _themeMode,
        onThemeModeChanged: _setThemeMode,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  const HomePage({super.key, required this.themeMode, required this.onThemeModeChanged});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<String> _links = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _recentVideos = [];

  @override
  void initState() {
    super.initState();
    _loadLinks();
    _loadRecentVideos();
  }

  Future<void> _loadLinks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _links = prefs.getStringList('video_links') ?? [
        'https://cdn.bitmovin.com/content/assets/playhouse-vr/m3u8s/105560.m3u8',
      ];
    });
  }

  Future<void> _saveLinks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('video_links', _links);
  }

  Future<void> _loadRecentVideos() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentVideos = prefs.getStringList('recent_videos') ?? [];
    });
  }

  Future<void> _saveRecentVideos() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('recent_videos', _recentVideos);
  }

  Future<void> _addRecentVideo(String filePath) async {
    setState(() {
      _recentVideos.remove(filePath); // Remove if already exists
      _recentVideos.insert(0, filePath); // Add to start
      if (_recentVideos.length > 8) {
        _recentVideos = _recentVideos.sublist(0, 8); // Keep max 8
      }
    });
    await _saveRecentVideos();
  }

  Future<void> _clearRecentVideos() async {
    setState(() {
      _recentVideos.clear();
    });
    await _saveRecentVideos();
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      final String filePath = video.path;
      await _addRecentVideo(filePath);
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
        title: Text(
          'VR Player',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
            onPressed: _showAddLinkDialog,
          ),
          IconButton(
            icon: Icon(Icons.video_library, color: Theme.of(context).colorScheme.primary),
            onPressed: _pickVideo,
            tooltip: 'Pick Video from Device',
          ),
          IconButton(
            icon: Icon(Icons.image, color: Theme.of(context).colorScheme.primary),
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
          PopupMenuButton<ThemeMode>(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                ? Icons.dark_mode
                : widget.themeMode == ThemeMode.light
                  ? Icons.light_mode
                  : Icons.brightness_auto,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Theme Mode',
            onSelected: widget.onThemeModeChanged,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.brightness_auto, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text('System'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.light_mode, color: Colors.amber),
                    const SizedBox(width: 8),
                    const Text('Light'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.dark_mode, color: Colors.blueGrey),
                    const SizedBox(width: 8),
                    const Text('Dark'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        children: [
          if (_recentVideos.isNotEmpty)
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.video_collection, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Recent Device Videos',
                            style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_forever, color: Colors.red),
                          tooltip: 'Clear Recent Videos',
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear Recent Videos'),
                                content: const Text('Are you sure you want to clear all recent videos?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Clear', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              _clearRecentVideos();
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentVideos.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.8,
                      ),
                      itemBuilder: (context, index) {
                        final path = _recentVideos[index];
                        final fileName = path.split(RegExp(r'[\\/]')).last;
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VideoPlayerPage(videoUrl: path),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.video_file, size: 32, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    fileName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                    title: Row(
                    children: [
                      Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                      'Video Links',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      ),
                    ],
                    ),
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit, color: Theme.of(context).colorScheme.primary),
                                onPressed: () => _showEditLinkDialog(index),
                                tooltip: 'Edit Link',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteLink(index),
                                tooltip: 'Delete Link',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                _saveLinks();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditLinkDialog(int index) {
    final TextEditingController linkController = TextEditingController(text: _links[index]);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Link'),
          content: TextField(
            controller: linkController,
            decoration: const InputDecoration(hintText: 'Enter new link'),
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
                  _links[index] = linkController.text;
                });
                _saveLinks();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _deleteLink(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Link'),
          content: const Text('Are you sure you want to delete this link?'),
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
                  _links.removeAt(index);
                });
                _saveLinks();
                Navigator.of(context).pop();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
                            activeTrackColor: Theme.of(context).colorScheme.primary,
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