import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:vector_map/src/data/map_layer.dart';
import 'package:vector_map/src/map_resolution.dart';

class DurationDebugger {
  int _lastDuration = 0;
  int _nextDuration = 0;
  DateTime? _lastStartTime;

  clear() {
    _nextDuration = 0;
    _lastStartTime = null;
  }

  update() {
    _lastDuration = _nextDuration;
    _lastStartTime = null;
  }

  openDuration() {
    _lastStartTime = DateTime.now();
  }

  closeDuration() {
    if (_lastStartTime != null) {
      DateTime end = DateTime.now();
      Duration duration = end.difference(_lastStartTime!);
      _nextDuration += duration.inMilliseconds;
    }
  }
}

class MapDebugger extends ChangeNotifier {
  int _layersCount = 0;
  int _featuresCount = 0;
  int _originalPointsCount = 0;
  int _simplifiedPointsCount = 0;

  DurationDebugger _drawableBuildDuration = DurationDebugger();
  DurationDebugger _bufferBuildDuration = DurationDebugger();

  DateTime? _initialMultiResolutionTime;
  Duration _multiResolutionDuration = Duration.zero;

  initialize(List<MapLayer> layers) {
    _layersCount = layers.length;
    for (MapLayer layer in layers) {
      _featuresCount += layer.dataSource.features.length;
      _originalPointsCount += layer.dataSource.pointsCount;
    }
    notifyListeners();
  }

  updateMapResolution(MapResolution mapResolution) {
    _simplifiedPointsCount = mapResolution.pointsCount;
    notifyListeners();
  }

  clearDrawableBuildDuration() {
    _drawableBuildDuration.clear();
  }

  updateDrawableBuildDuration() {
    _drawableBuildDuration.update();
    notifyListeners();
  }

  openDrawableBuildDuration() {
    _drawableBuildDuration.openDuration();
  }

  closeDrawableBuildDuration() {
    _drawableBuildDuration.closeDuration();
  }

  clearBufferBuildDuration() {
    _bufferBuildDuration.clear();
  }

  updateBufferBuildDuration() {
    _bufferBuildDuration.update();
    notifyListeners();
  }

  openBufferBuildDuration() {
    _bufferBuildDuration.openDuration();
  }

  closeBufferBuildDuration() {
    _bufferBuildDuration.closeDuration();
  }

  openMultiResolutionTime() {
    _initialMultiResolutionTime = DateTime.now();
    _multiResolutionDuration = Duration.zero;
  }

  closeMultiResolutionTime() {
    if (_initialMultiResolutionTime != null) {
      DateTime end = DateTime.now();
      _multiResolutionDuration = end.difference(_initialMultiResolutionTime!);
      notifyListeners();
    }
  }
}

class MapDebuggerWidget extends StatefulWidget {
  MapDebuggerWidget(this.debugger);

  final MapDebugger debugger;

  @override
  State<StatefulWidget> createState() {
    return MapDebuggerState();
  }
}

class MapDebuggerState extends State<MapDebuggerWidget> {
  String formatInt(int value) {
    String str = value.toString();
    String fmt = '';
    int indexGroup = 3 - str.length % 3;
    if (indexGroup == 3) {
      indexGroup = 0;
    }
    for (int i = 0; i < str.length; i++) {
      fmt += str.substring(i, i + 1);
      indexGroup++;
      if (indexGroup == 3 && i < str.length - 1) {
        fmt += ',';
        indexGroup = 0;
      }
    }
    return fmt;
  }

  @override
  Widget build(BuildContext context) {
    Duration drawableDuration = Duration(
        milliseconds: widget.debugger._drawableBuildDuration._lastDuration);
    Duration bufferDuration = Duration(
        milliseconds: widget.debugger._bufferBuildDuration._lastDuration);

    return Column(children: [
      Padding(
          padding: EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: Text('Quantities',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      _buildFormattedInt('Layers: ', widget.debugger._layersCount),
      _buildFormattedInt('Features: ', widget.debugger._featuresCount),
      _buildFormattedInt(
          'Original points: ', widget.debugger._originalPointsCount),
      _buildFormattedInt(
          'Simplified points: ', widget.debugger._simplifiedPointsCount),
      Padding(
          padding: EdgeInsets.fromLTRB(0, 12, 0, 12),
          child: Text('Last durations',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      _buildDuration(
          'Multi resolution: ', widget.debugger._multiResolutionDuration),
      _buildDuration('-- Drawable build: ', drawableDuration),
      _buildDuration('-- Buffer build: ', bufferDuration)
    ], crossAxisAlignment: CrossAxisAlignment.start);
  }

  Widget _buildFormattedInt(String name, int value) {
    return _buildItem(name, formatInt(value));
  }

  Widget _buildDuration(String name, Duration value) {
    return _buildItem(name, value.inMilliseconds.toString() + 'ms');
  }

  Widget _buildItem(String name, String value) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0, 4, 0, 0),
        child: RichText(
          text: new TextSpan(
            style: TextStyle(fontSize: 12),
            children: <TextSpan>[
              new TextSpan(text: name),
              new TextSpan(
                  text: value,
                  style: new TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    widget.debugger.addListener(_refresh);
  }

  @override
  void didUpdateWidget(MapDebuggerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.debugger.removeListener(_refresh);
    widget.debugger.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.debugger.removeListener(_refresh);
    super.dispose();
  }

  _refresh() {
    Future.delayed(Duration.zero, () async {
      if (mounted) {
        setState(() {
          // rebuild
        });
      }
    });
  }
}
