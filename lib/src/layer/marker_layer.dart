import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/src/map/map.dart';
import 'package:latlong/latlong.dart';
import 'speech_bubble.dart';

class MarkerLayerOptions extends LayerOptions {
  final List<Marker> markers;
  MarkerLayerOptions({this.markers = const [], rebuild})
      : super(rebuild: rebuild);
}

class Anchor {
  final double left;
  final double top;

  Anchor(this.left, this.top);

  Anchor._(double width, double height, AnchorAlign alignOpt)
      : left = _leftOffset(width, alignOpt),
        top = _topOffset(width, alignOpt);

  static double _leftOffset(double width, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.left:
        return 0.0;
      case AnchorAlign.right:
        return width;
      case AnchorAlign.top:
      case AnchorAlign.bottom:
      case AnchorAlign.center:
      default:
        return width / 2;
    }
  }

  static double _topOffset(double height, AnchorAlign alignOpt) {
    switch (alignOpt) {
      case AnchorAlign.top:
        return 0.0;
      case AnchorAlign.bottom:
        return height;
      case AnchorAlign.left:
      case AnchorAlign.right:
      case AnchorAlign.center:
      default:
        return height / 2;
    }
  }

  factory Anchor._forPos(AnchorPos pos, double width, double height) {
    if (pos == null) return Anchor._(width, height, null);
    if (pos.value is AnchorAlign) return Anchor._(width, height, pos.value);
    if (pos.value is Anchor) return pos.value;
    throw Exception('Unsupported AnchorPos value type: ${pos.runtimeType}.');
  }
}

class AnchorPos<T> {
  AnchorPos._(this.value);
  T value;
  static AnchorPos exactly(Anchor anchor) => AnchorPos._(anchor);
  static AnchorPos align(AnchorAlign alignOpt) => AnchorPos._(alignOpt);
}

enum AnchorAlign {
  left,
  right,
  top,
  bottom,
  center,
}

class Marker {
  final LatLng point;
  final WidgetBuilder builder;
  final double width;
  final double height;
  final Anchor anchor;
  final GlobalKey globalKey = GlobalKey();
  final String speech;
  Size layoutSize;
  Offset layoutPosition;
  Marker({
    @required this.point,
    @required this.builder,
    this.width: 30.0,
    this.height: 30.0,
    this.speech,
    AnchorPos anchorPos,
    GlobalKey globalKey: GlobalKey()
  }) : this.anchor = Anchor._forPos(anchorPos, width, height);

  bool get hasSpeech => this.speech != null && this.speech.isNotEmpty;
}

class MarkerLayer extends StatefulWidget {
  final MarkerLayerOptions markerOpts;
  final MapState map;
  final Stream<Null> stream;
  MarkerLayer(this.markerOpts, this.map, this.stream);

  @override
  State<StatefulWidget> createState() {
    return _MarkerLayerState();
  }
}

class _MarkerLayerState extends State<MarkerLayer> {
  void _afterLayout(_) {
    _getSizes();
  }

  void _getSizes() {
    bool needsRebuild = false;
    for (var markerOpt in widget.markerOpts.markers) {
      final RenderBox renderBoxRed =
          markerOpt.globalKey.currentContext?.findRenderObject();
      if (renderBoxRed == null) {
        continue;
      }

      if (markerOpt.hasSpeech && markerOpt.layoutSize != renderBoxRed.size) {
        needsRebuild = true;
      }
      markerOpt.layoutSize = renderBoxRed.size;
      markerOpt.layoutPosition = renderBoxRed.localToGlobal(Offset.zero);
    }
    if (needsRebuild) {
      setState(() {});
    }
  }

  Widget build(BuildContext context) {
    return new StreamBuilder<int>(
      stream: widget.stream, // a Stream<int> or null
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        return LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          List<Widget> markersWithSpeech = [];
          var markers = <Widget>[];
          for (var markerOpt in widget.markerOpts.markers) {
            var pos = widget.map.project(markerOpt.point);
            pos = pos.multiplyBy(
                    widget.map.getZoomScale(widget.map.zoom, widget.map.zoom)) -
                widget.map.getPixelOrigin();

            var pixelPosX =
                (pos.x - (markerOpt.width - markerOpt.anchor.left)).toDouble();
            var pixelPosY =
                (pos.y - (markerOpt.height - markerOpt.anchor.top)).toDouble();

            if (!widget.map.bounds.contains(markerOpt.point)) {
              continue;
            }
            Widget markerWidget = Positioned(
                key: markerOpt.globalKey,
                // width: markerOpt.width,
                //  height: markerOpt.height,
                left: pixelPosX,
                top: pixelPosY,
                child: markerOpt.builder(context));

            if (markerOpt.hasSpeech &&
                markerOpt.layoutSize != null &&
                !markerOpt.layoutSize.isEmpty) {
              //add speaking widgets to end so they appear over top of others
              markers.add(markerWidget);
              double centerX = pixelPosX + markerOpt.layoutSize.width / 2;
              double centerY = pixelPosY + markerOpt.layoutSize.height / 2;
              TooltipDirection popupDirection;
              double left;
              double right;
              double top;
              double bottom;
              if (centerX > constraints.maxWidth / 2 &&
                  centerY > constraints.maxHeight / 2) {
                popupDirection = TooltipDirection.up_left;
                right = constraints.maxWidth -
                    pixelPosX -
                    markerOpt.layoutSize.width;
                bottom = constraints.maxHeight - pixelPosY;
              } else if (centerX > constraints.maxWidth / 2 &&
                  centerY <= constraints.maxHeight / 2) {
                popupDirection = TooltipDirection.down_left;

                right = constraints.maxWidth -
                    pixelPosX -
                    markerOpt.layoutSize.width;
                top = pixelPosY + markerOpt.layoutSize.height;
              } else if (centerX <= constraints.maxWidth / 2 &&
                  centerY > constraints.maxHeight / 2) {
                popupDirection = TooltipDirection.up_right;
                left = pixelPosX;
                bottom = constraints.maxHeight - pixelPosY;
              } else if (centerX <= constraints.maxWidth / 2 &&
                  centerY <= constraints.maxHeight / 2) {
                popupDirection = TooltipDirection.down_right;
                left = pixelPosX;
                top = pixelPosY + markerOpt.layoutSize.height;
              }
              markersWithSpeech.add(Positioned(
                  width: 120,
                  //  height: markerOpt.height,
                  left: left,
                  right: right,
                  bottom: bottom,
                  top: top,
                  child: SpeechBubble(
                      popupDirection: popupDirection,
                      content: new Material(
                          color: Colors.white,
                          child: Text(
                            markerOpt.speech,
                            softWrap: true,
                            style: TextStyle(color: Colors.black),
                          )))));
            } else {
              markers.insert(0, markerWidget);
            }
          }

          markers.addAll(markersWithSpeech);
          WidgetsBinding.instance.addPostFrameCallback(_afterLayout);

          return new Container(
            child: new Stack(
              children: markers,
            ),
          );
        });
      },
    );
  }
}
