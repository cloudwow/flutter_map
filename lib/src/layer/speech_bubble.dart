import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

enum TooltipDirection { up_left, down_left, up_right, down_right, left, right }
enum ShowCloseButton { inside, outside, none }
enum ClipAreaShape { oval, rectangle }

class SpeechBubble extends StatelessWidget {
  final bool hasShadow = true;

  /// The content of the Tooltip
  final Widget content;
  final Offset offset;

  final double borderRadius;
  final double arrowBaseWidth;
  final double arrowTipDistance;
  final Color borderColor;
  final double borderWidth;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double arrowLength;
final TooltipDirection popupDirection;

  SpeechBubble({
    this.content,
    this.offset: const Offset(60.0, 0.0),
    this.popupDirection,
    this.top,
    this.right,
    this.bottom,
    this.left,
    this.arrowBaseWidth = 20.0,
    this.arrowTipDistance = 2.0,
    this.arrowLength = 20.0,
    this.borderWidth = 2.0,
    this.borderRadius = 10.0,
    this.borderColor: Colors.black,
  });


  @override
  Widget build(BuildContext context) {
    return   Column(mainAxisSize: MainAxisSize.min, children: [
      Container(

        decoration: ShapeDecoration(
            color: Colors.white,
            shadows: hasShadow
                ? [BoxShadow(color: Colors.black54, blurRadius: 10.0, spreadRadius: 5.0)]
                : null,
            shape: _BubbleShape(popupDirection, borderRadius, arrowBaseWidth, arrowTipDistance,
                borderColor, borderWidth, left, top, right, bottom)),
        margin: _getBallonContainerMargin(),
        child: content,
      )
    ]);
  }

  EdgeInsets _getBallonContainerMargin() {
   
    switch (popupDirection) {
      //
      case TooltipDirection.down_right:
      case TooltipDirection.down_left:
        return EdgeInsets.only(
          top: 15,
        );

      case TooltipDirection.up_left:
      case TooltipDirection.up_right:
        return EdgeInsets.only(bottom: 15);

      case TooltipDirection.left:
        return EdgeInsets.only(right: 15);

      case TooltipDirection.right:
        return EdgeInsets.only(left: 15);

      default:
        throw AssertionError(popupDirection);
    }
  }
}

class _BubbleShape extends ShapeBorder {
  final double arrowBaseWidth;
  final double arrowTipDistance;
  final double borderRadius;
  final Color borderColor;
  final double borderWidth;
  final double left, top, right, bottom;
  final TooltipDirection popupDirection;

  _BubbleShape(this.popupDirection, this.borderRadius, this.arrowBaseWidth, this.arrowTipDistance,
      this.borderColor, this.borderWidth, this.left, this.top, this.right, this.bottom);

  @override
  EdgeInsetsGeometry get dimensions => new EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    return new Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  Path addTop(Rect rect, Path path) {
    // assume cursor is at top left (after corner)
    path
      // to top right
      ..lineTo(rect.right - borderRadius, rect.top)
      // top right corner
      ..arcToPoint(Offset(rect.right, rect.top + borderRadius),
          radius: new Radius.circular(borderRadius), clockwise: true);
    return path;
  }

  Path addRight(Rect rect, Path path) {
    // assume cursor is at top right (after corner)
    path
      // to bottom right
      ..lineTo(rect.right, rect.bottom - borderRadius)
      // bottom right corner
      ..arcToPoint(Offset(rect.right - borderRadius, rect.bottom),
          radius: new Radius.circular(borderRadius), clockwise: true);
    return path;
  }

  Path addBottom(Rect rect, Path path) {
    // assume cursor is at bottom right (after corner)
    path
      // to bottom left
      ..lineTo(rect.left + borderRadius, rect.bottom)
      // bottom right corner
      ..arcToPoint(Offset(rect.left, rect.bottom - borderRadius),
          radius: new Radius.circular(borderRadius), clockwise: true);
    return path;
  }

  Path addLeft(Rect rect, Path path) {
    // assume cursor is at bottom left (after corner)
    path
      // to top left
      ..lineTo(rect.left, rect.top + borderRadius)
      // bottom right corner
      ..arcToPoint(Offset(rect.left + borderRadius, rect.top),
          radius: new Radius.circular(borderRadius), clockwise: true);
    return path;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    //

    switch (popupDirection) {
      //

      case TooltipDirection.down_left:
        var path = Path();
        path.moveTo(rect.right, rect.top + borderRadius);
        addRight(rect, path);
        addBottom(rect, path);
        addLeft(rect, path);
        double arrowLeft = max(rect.left + borderRadius, rect.right - 20 - 10 - borderRadius);
        path
          ..lineTo(arrowLeft, rect.top)
          ..lineTo(arrowLeft + 10, rect.top - 20)
          ..lineTo(arrowLeft + 20, rect.top);
        addTop(rect, path);
        return path;

      case TooltipDirection.down_right:
        var path = Path();
        path.moveTo(rect.right, rect.top + borderRadius);
        addRight(rect, path);
        addBottom(rect, path);
        addLeft(rect, path);
        double arrowLeft = min(rect.left + borderRadius + 10, rect.right - 20 - borderRadius);
        path
          ..lineTo(arrowLeft, rect.top)
          ..lineTo(arrowLeft + 10, rect.top - 20)
          ..lineTo(arrowLeft + 20, rect.top);
        addTop(rect, path);
        return path;

      case TooltipDirection.up_right:
        var path = Path();
        path.moveTo(rect.left, rect.bottom - borderRadius);
        addLeft(rect, path);
        addTop(rect, path);
        addRight(rect, path);
        double arrowRight = min(rect.right - borderRadius, rect.left + 30 + borderRadius);
        path
          ..lineTo(arrowRight, rect.bottom)
          ..lineTo(arrowRight - 10, rect.bottom + 20)
          ..lineTo(arrowRight - 20, rect.bottom);
        addBottom(rect, path);
        return path;
      case TooltipDirection.up_left:
        var path = Path();
        path.moveTo(rect.left, rect.bottom - borderRadius);
        addLeft(rect, path);
        addTop(rect, path);
        addRight(rect, path);
        double arrowRight = max(rect.right - borderRadius - 10, rect.left + 20 + borderRadius);
        path
          ..lineTo(arrowRight, rect.bottom)
          ..lineTo(arrowRight - 10, rect.bottom + 20)
          ..lineTo(arrowRight - 20, rect.bottom);
        addBottom(rect, path);
        return path;
      case TooltipDirection.right:
        var path = Path();
        path.moveTo(rect.left + borderRadius, rect.top);
        addTop(rect, path);
        addRight(rect, path);
        addBottom(rect, path);
        double arrowBottom = max(rect.bottom - borderRadius - 15, rect.top + 20 + borderRadius);
        path
          ..lineTo(rect.left, arrowBottom)
          ..lineTo(rect.left - 20, arrowBottom - 10)
          ..lineTo(rect.left, arrowBottom - 20);
        addLeft(rect, path);
        return path;
      case TooltipDirection.right:
        var path = Path();
        path.moveTo(rect.right, rect.bottom);
        addBottom(rect, path);
        addLeft(rect, path);
        addTop(rect, path);
        double arrowTop = min(rect.top + borderRadius + 20, rect.bottom - 20 - borderRadius);
        path
          ..lineTo(rect.right, arrowTop)
          ..lineTo(rect.right + 20, arrowTop + 10)
          ..lineTo(rect.right, arrowTop + 20);
        addRight(rect, path);
        return path;

      default:
        throw AssertionError(popupDirection);
    }
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection textDirection}) {
    Paint paint = new Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawPath(getOuterPath(rect), paint);
    paint = new Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    if (right == 0.0) {
      if (top == 0.0 && bottom == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.top)
              ..lineTo(rect.right, rect.bottom),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.top + borderWidth / 2)
              ..lineTo(rect.right, rect.bottom - borderWidth / 2),
            paint);
      }
    }
    if (left == 0.0) {
      if (top == 0.0 && bottom == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.left, rect.top)
              ..lineTo(rect.left, rect.bottom),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.left, rect.top + borderWidth / 2)
              ..lineTo(rect.left, rect.bottom - borderWidth / 2),
            paint);
      }
    }
    if (top == 0.0) {
      if (left == 0.0 && right == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.top)
              ..lineTo(rect.left, rect.top),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right - borderWidth / 2, rect.top)
              ..lineTo(rect.left + borderWidth / 2, rect.top),
            paint);
      }
    }
    if (bottom == 0.0) {
      if (left == 0.0 && right == 0.0) {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right, rect.bottom)
              ..lineTo(rect.left, rect.bottom),
            paint);
      } else {
        canvas.drawPath(
            new Path()
              ..moveTo(rect.right - borderWidth / 2, rect.bottom)
              ..lineTo(rect.left + borderWidth / 2, rect.bottom),
            paint);
      }
    }
  }

  @override
  ShapeBorder scale(double t) {
    return new _BubbleShape(popupDirection, borderRadius, arrowBaseWidth, arrowTipDistance,
        borderColor, borderWidth, left, top, right, bottom);
  }
}
