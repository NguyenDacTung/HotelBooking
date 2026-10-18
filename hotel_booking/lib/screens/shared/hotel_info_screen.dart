import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../widgets/common.dart';

Future<void> openTrusted(
  BuildContext context,
  Uri uri, {
  Set<String> schemes = const {'https'},
}) async {
  if (!schemes.contains(uri.scheme) || uri.userInfo.isNotEmpty) {
    message(context, 'Liên kết không hợp lệ');
    return;
  }
  try {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        context.mounted) {
      message(context, 'Thiết bị chưa có ứng dụng mở liên kết này');
    }
  } catch (_) {
    if (context.mounted) message(context, 'Không mở được liên kết');
  }
}

class HotelInfoScreen extends StatefulWidget {
  const HotelInfoScreen({super.key});
  @override
  State<HotelInfoScreen> createState() => _InfoState();
}

class _InfoState extends State<HotelInfoScreen> {
  Json? data;
  String? error;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final d = await context.read<ApiService>().request(
        'GET',
        '/hotel/info',
      ) as Json;
      if (mounted) {
        setState(() {
          data = d;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TETRA Hotel')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (error != null) ErrorPanel(error!, load),
        if (data == null && error == null) const LinearProgressIndicator(),
        if (data != null) ...[
          Text(
            data!['name'],
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if ((data!['video_url'] ?? '').isNotEmpty)
            HotelVideo(
              url: data!['video_url'],
              caption: data!['video_caption'] ?? '',
            ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Vị trí khách sạn'),
            subtitle: const Text('Xem bản đồ và chỉ đường'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const HotelMapScreen()),
            ),
          ),
          if ((data!['hotel_phone'] ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: Text(data!['hotel_phone']),
              onTap: () => openTrusted(
                context,
                Uri(scheme: 'tel', path: data!['hotel_phone']),
                schemes: {'tel'},
              ),
            ),
          if ((data!['hotel_email'] ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: Text(data!['hotel_email']),
              onTap: () => openTrusted(
                context,
                Uri(scheme: 'mailto', path: data!['hotel_email']),
                schemes: {'mailto'},
              ),
            ),
          if ((data!['website'] ?? '').isNotEmpty)
            ListTile(
              leading: const Icon(Icons.public),
              title: const Text('Website'),
              onTap: () => openTrusted(context, Uri.parse(data!['website'])),
            ),
        ],
      ],
    ),
  );
}

class HotelVideo extends StatefulWidget {
  final String url, caption;
  const HotelVideo({super.key, required this.url, required this.caption});
  @override
  State<HotelVideo> createState() => _VideoState();
}

class _VideoState extends State<HotelVideo> with WidgetsBindingObserver {
  VideoPlayerController? controller;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  Future<void> init() async {
    final uri = Uri.tryParse(widget.url);
    if (uri == null || uri.scheme != 'https') {
      setState(() => error = 'Video cần địa chỉ HTTPS hợp lệ');
      return;
    }
    controller = VideoPlayerController.networkUrl(uri);
    try {
      await controller!.initialize();
      if (mounted) setState(() => error = null);
    } catch (_) {
      if (mounted) setState(() => error = 'Không tải được video');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller?.dispose();
    super.dispose();
  }

  Widget player() => AspectRatio(
    aspectRatio: controller!.value.aspectRatio,
    child: VideoPlayer(controller!),
  );
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (error != null)
            Text(error!)
          else if (controller?.value.isInitialized != true)
            const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            player(),
            VideoProgressIndicator(controller!, allowScrubbing: true),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ValueListenableBuilder<VideoPlayerValue>(
                  valueListenable: controller!,
                  builder: (c, v, _) => IconButton(
                    tooltip: v.isPlaying ? 'Tạm dừng' : 'Phát video',
                    icon: Icon(v.isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () =>
                        v.isPlaying ? controller!.pause() : controller!.play(),
                  ),
                ),
                IconButton(
                  tooltip: 'Toàn màn hình',
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (c) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(title: const Text('Video khách sạn')),
                          body: SafeArea(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: Center(child: player())),
                                VideoProgressIndicator(
                                  controller!,
                                  allowScrubbing: true,
                                ),
                                ValueListenableBuilder<VideoPlayerValue>(
                                  valueListenable: controller!,
                                  builder: (_, v, _) => IconButton(
                                    color: Colors.white,
                                    tooltip: v.isPlaying
                                        ? 'Tạm dừng'
                                        : 'Phát video',
                                    icon: Icon(
                                      v.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    onPressed: () => v.isPlaying
                                        ? controller!.pause()
                                        : controller!.play(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                    controller?.pause();
                  },
                ),
              ],
            ),
          ],
          if (widget.caption.isNotEmpty) Text(widget.caption),
        ],
      ),
    ),
  );
}

class HotelMapScreen extends StatefulWidget {
  const HotelMapScreen({super.key});
  @override
  State<HotelMapScreen> createState() => _MapState();
}

class _MapState extends State<HotelMapScreen> {
  static const lat = 10.855802343959219, lon = 106.78566243940791;
  final controller = MapController.customLayer(
    initPosition: GeoPoint(latitude: lat, longitude: lon),
    customTile: CustomTile(
      sourceName: 'TETRAOpenStreetMap',
      urlsServers: [TileURLs(url: 'https://tile.openstreetmap.org/')],
      tileExtension: '.png',
      tileSize: 256,
    ),
  );
  String? distance;
  bool locating = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) {
          message(context, 'Hãy bật vị trí nếu muốn tính khoảng cách');
        }
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied ||
          p == LocationPermission.deniedForever) {
        if (mounted) {
          message(
            context,
            'Chưa được cấp vị trí. Bạn vẫn có thể xem khách sạn và mở chỉ đường',
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final km =
          Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lon) /
          1000;
      if (mounted) {
        setState(
          () => distance =
              'Khoảng cách đường thẳng: ${km.toStringAsFixed(1)} km (không phải quãng đường di chuyển)',
        );
      }
    } catch (_) {
      if (mounted) message(context, 'Không lấy được vị trí hiện tại');
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Vị trí TETRA Hotel')),
    body: Column(
      children: [
        Expanded(
          child: OSMFlutter(
            controller: controller,
            osmOption: const OSMOption(
              zoomOption: ZoomOption(
                initZoom: 16,
                minZoomLevel: 3,
                maxZoomLevel: 19,
              ),
            ),
            onMapIsReady: (ready) async {
              if (ready && mounted) {
                await controller.addMarker(
                  GeoPoint(latitude: lat, longitude: lon),
                  markerIcon: const MarkerIcon(
                    icon: Icon(Icons.location_pin, color: Colors.red, size: 48),
                  ),
                );
              }
            },
          ),
        ),
        const Text('© OpenStreetMap contributors'),
        if (distance != null)
          Padding(padding: const EdgeInsets.all(8), child: Text(distance!)),
        SafeArea(
          child: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: locating ? null : locate,
                icon: const Icon(Icons.my_location),
                label: Text(
                  locating ? 'Đang lấy vị trí…' : 'Khoảng cách từ tôi',
                ),
              ),
              FilledButton.icon(
                onPressed: () => openTrusted(
                  context,
                  Uri.https('www.google.com', '/maps/dir/', {
                    'api': '1',
                    'destination': '$lat,$lon',
                  }),
                ),
                icon: const Icon(Icons.directions),
                label: const Text('Chỉ đường'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
