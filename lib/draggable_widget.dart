library draggable_widget;

import 'dart:math';
import 'package:flutter/material.dart';

part "drag_controller.dart";

enum AnchoringPosition {
  topLeft,
  topRight,
  topCenter,
  bottomLeft,
  bottomRight,
  center,
  bottomCenter
}

///
/// A widget that can be dragged.
/// Must be a direct child of a [Stack].
///
class DraggableWidget extends StatefulWidget {
  ///
  /// The widget that will be wrapped with this DraggableWidget
  ///
  final Widget child;

  final Function? onPointerDown;
  final Function? onPointerUp;
  final Function? onPointerMove;
  final Function? onAnchor;

  /// The padding around the widget
  final EdgeInsets padding;

  /// Initial location of the widget, default to [AnchoringPosition.bottomLeft]
  final AnchoringPosition initialPosition;

  /// Intially should the widget be visible or not, default to [true]
  final bool initialVisibility;

  /// The top bottom pargin to create the bottom boundary for the widget, for example if you have a [BottomNavigationBar],
  /// then you may need to set the bottom boundary so that the draggable button can't get on top of the [BottomNavigationBar]
  final EdgeInsets margin;

  /// Shadow's border radius for the draggable widget, default to 10
  final double shadowBorderRadius;

  /// A drag controller to show/hide or move the widget around the screen
  final DragController? dragController;

  /// [BoxShadow] when the widget is not being dragged, default to
  /// ```Dart
  ///const BoxShadow(
  ///     color: Colors.black38,
  ///    offset: Offset(0, 4),
  ///    blurRadius: 2,
  ///  ),
  /// ```
  final BoxShadow? normalShadow;

  /// [BoxShadow] when the widget is being dragged
  ///```Dart
  ///const BoxShadow(
  ///     color: Colors.black38,
  ///    offset: Offset(0, 10),
  ///    blurRadius: 10,
  ///  ),
  /// ```
  final BoxShadow? draggingShadow;

  /// Touch Delay Duration. Default value is zero. When set, drag operations will trigger after the duration.
  final Duration touchDelay;

  final double initialHeight;
  final double initialWidth;

  DraggableWidget({
    Key? key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.initialPosition = AnchoringPosition.bottomLeft,
    this.initialVisibility = true,
    this.margin = EdgeInsets.zero,
    this.shadowBorderRadius = 10,
    required this.initialHeight,
    required this.initialWidth,
    this.dragController,
    this.touchDelay = Duration.zero,
    this.normalShadow = const BoxShadow(
      color: Colors.black38,
      offset: Offset(0, 4),
      blurRadius: 2,
    ),
    this.draggingShadow = const BoxShadow(
      color: Colors.black38,
      offset: Offset(0, 10),
      blurRadius: 10,
    ),
    this.onPointerDown,
    this.onPointerUp,
    this.onAnchor,
    this.onPointerMove,
  });
  @override
  _DraggableWidgetState createState() => _DraggableWidgetState();

  ///
  /// Calculates the [Offset] (relative to a container of size [containerSize]) of an item of size [itemSize] anchored at [position].
  /// In other words, "convert the AnchoringPosition of this item anchored in this container to an Offset that describes where it is inside the container".
  /// Note this returns an Offset to the center of the item, not the top left.
  ///
  static Offset getOffsetForPosition(
      AnchoringPosition position, Size itemSize, Size containerSize) {
    Offset offset = Offset.zero;
    switch (position) {
      case AnchoringPosition.topLeft:
        offset = Offset.zero;
        break;
      case AnchoringPosition.topRight:
        offset = Offset(containerSize.width - itemSize.width, 0);
        break;
      case AnchoringPosition.bottomLeft:
        offset = Offset(0, containerSize.height - itemSize.height);
        break;
      case AnchoringPosition.bottomRight:
        offset = Offset(containerSize.width - itemSize.width,
            containerSize.height - itemSize.height);
        break;
      case AnchoringPosition.center:
        offset = Offset((containerSize.width - itemSize.width) / 2,
            (containerSize.height - itemSize.height) / 2);
        break;
      case AnchoringPosition.topCenter:
        offset = Offset((containerSize.width - itemSize.width) / 2, 0);
        break;
      case AnchoringPosition.bottomCenter:
        offset = Offset((containerSize.width - itemSize.width) / 2,
            containerSize.height - itemSize.height);
        break;
      default:
        throw Exception();
    }
    return offset;
  }
}

class _DraggableWidgetState extends State<DraggableWidget>
    with SingleTickerProviderStateMixin {
  ///
  /// The current position of the draggable widget. This may change every frame if the widget is moving.
  ///
  Offset _currentOffset = Offset.zero;

  ///
  /// The target rect where the draggable widget is moving to (meaning the Offset where the widget will end up when it has finished moving).
  ///
  late RelativeRect _targetRect;

  ///
  /// A convenience getter to calculate the boundary Rect that surrounds the draggable widget;
  ///
  Size? containerSize;

  late AnimationController animationController;
  Animation<RelativeRect>? animation;

  bool offstage = true;

  ///
  /// The last known anchor position of the draggable widget. This does not mean the widget is actually located at this position - it may have moved away under a drag gesture that's ongoing,
  /// or it may be moving towards this position after a drag was released.

  AnchoringPosition? anchorPosition;

  final key = GlobalKey();

  bool dragging = false;

  bool? visible;

  bool get currentVisibilty => visible ?? widget.initialVisibility;

  late bool isStillTouching;

  @override
  void initState() {
    anchorPosition = widget.initialPosition;
    animationController = AnimationController(
      value: 1,
      vsync: this,
      duration: Duration(milliseconds: 150),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener(
        (status) {
          if (status == AnimationStatus.completed) {
            _currentOffset = Offset(_targetRect.left, _targetRect.top);
          }
        },
      );

    widget.dragController?._addState(this);

    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) async {
      var rb = context.findRenderObject() as RenderBox;
      containerSize = rb.constraints.biggest;

      setState(() {
        offstage = false;
        _currentOffset = DraggableWidget.getOffsetForPosition(
            widget.initialPosition,
            Size(widget.initialWidth, widget.initialHeight),
            containerSize!);
        _targetRect = RelativeRect.fromSize(
            Rect.fromPoints(
                _currentOffset,
                _currentOffset.translate(
                    widget.initialWidth, widget.initialHeight)),
            containerSize!);
        _targetRect.shift(_currentOffset);
        animation = AlwaysStoppedAnimation<RelativeRect>(_targetRect);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  AnchoringPosition _calculateAnchorPosition(double x, double y) {
    var rb = context.findRenderObject() as RenderBox;
    containerSize = rb.constraints.biggest;

    // top
    if (y <= containerSize!.height / 4) {
      if (x <= containerSize!.width / 4) {
        return AnchoringPosition.topLeft;
      } else if (x > containerSize!.width / 4 &&
          x < 3 * containerSize!.width / 4) {
        return AnchoringPosition.topCenter;
      } else {
        return AnchoringPosition.topRight;
      }
      // bottom
    } else if (y >= 3 * containerSize!.height / 4) {
      if (x < containerSize!.width / 4) {
        return AnchoringPosition.bottomLeft;
      } else if (x > containerSize!.width / 4 &&
          x < 3 * containerSize!.width / 4) {
        return AnchoringPosition.bottomCenter;
      } else {
        return AnchoringPosition.bottomRight;
      }
    } else {
      return AnchoringPosition.center;
    }
  }

  void _setTargetOffsetFromPosition(
      AnchoringPosition target, Animation<double> controller,
      {Size? size}) {
    // if size is null, assume we want to animate to inflate to the container size
    final widgetSize = size ?? containerSize!;

    Offset _targetOffset = DraggableWidget.getOffsetForPosition(
        target, widgetSize, containerSize!);

    var begin = RelativeRect.fromSize(
        Rect.fromLTWH(_currentOffset.dx, _currentOffset.dy, widgetSize.width,
            widgetSize.height),
        containerSize!);

    _targetRect = RelativeRect.fromSize(
        Rect.fromLTWH(_targetOffset.dx, _targetOffset.dy, widgetSize.width,
            widgetSize.height),
        containerSize!);

    animation = RelativeRectTween(
      begin: begin,
      end: _targetRect,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));
  }

  void _showWidget() {
    setState(() {
      visible = true;
    });
  }

  void _hideWidget() {
    setState(() {
      visible = false;
    });
  }

  Future _animateTo(AnchoringPosition position, {Size? size}) async {
    if (animationController.isAnimating) {
      animationController.stop();
    }
    animationController.reset();

    _setTargetOffsetFromPosition(position, animationController, size: size);

    await animationController.forward();
    if (widget.onAnchor != null) widget.onAnchor!(position);
  }

  void _setAvatarOffsetFromFingerPosition(Offset fingerOffset) {
    // assume the avatar's size hasn't changed since _targetRect was last updated
    final widgetSize = _targetRect.toSize(containerSize!);
    // set the offset of the avatar to the finger offset, translated by half the width/height
    // so the drag appears to move from the center, not the top left
    _currentOffset =
        fingerOffset.translate(-widgetSize.width / 2, -widgetSize.height / 2);

    // then, cap the x/y offset to make sure the avatar can't go offscreen.
    _currentOffset = Offset(
        max(-widgetSize.width / 2, min(containerSize!.width - (widgetSize.width / 2), _currentOffset.dx)),
        max(-widgetSize.height / 2,
            min(containerSize!.height - (widgetSize.height / 2), _currentOffset.dy)));
  }

  @override
  Widget build(BuildContext context) {
    // we need to wait one frame for the container dimensions to be calculated
    if (animation == null) {
      return Container();
    }
    List<BoxShadow> shadows = [];
    if (dragging && widget.draggingShadow != null) {
      shadows = [widget.draggingShadow!];
    } else if (widget.normalShadow != null) {
      shadows = [widget.normalShadow!];
    }

    return Stack(fit: StackFit.loose, children: [
      Positioned.fromRelativeRect(
        rect: animation!.value,
        child: AnimatedSwitcher(
          duration: Duration(
            milliseconds: 150,
          ),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: !currentVisibilty
              ? Container()
              : Listener(
                  onPointerUp: (v) async {
                    if (!isStillTouching) {
                      return;
                    }

                    if (widget.onPointerUp != null) widget.onPointerUp!();
                    isStillTouching = false;

                    _setAvatarOffsetFromFingerPosition(v.position);

                    anchorPosition = _calculateAnchorPosition(
                        v.position.dx, v.position.dy);

                    setState(() {
                      dragging = false;
                    });
                    _animateTo(anchorPosition!,
                        size: _targetRect.toSize(containerSize!));
                  },
                  onPointerDown: (v) async {
                    if (widget.dragController?.disabled == true) return;
                    isStillTouching = false;
                    await Future.delayed(widget.touchDelay);
                    if (widget.onPointerDown != null) widget.onPointerDown!();
                    isStillTouching = true;
                  },
                  // this is where we need to update the avatar's position from the finger position
                  onPointerMove: (v) async {
                    if (!isStillTouching) {
                      return;
                    }
                    if (animationController.isAnimating) {
                      animationController.stop();
                      animationController.reset();
                    }
                    if (widget.onPointerMove != null) widget.onPointerMove!();

                    // get the local offset of the finger
                    final fingerOffset =
                        (context.findRenderObject() as RenderBox)
                            .globalToLocal(v.position);

                    _setAvatarOffsetFromFingerPosition(v.position);

                    final widgetSize = _targetRect.toSize(containerSize!);

                    animation = AlwaysStoppedAnimation<RelativeRect>(
                        RelativeRect.fromRect(
                            Rect.fromLTWH(_currentOffset.dx, _currentOffset.dy,
                                widgetSize.width, widgetSize.height),
                            Offset.zero & containerSize!));
                    setState(() {});
                  },
                  child: Offstage(
                    offstage: offstage,
                    child: Container(
                      padding: widget.padding,
                      alignment: Alignment.topLeft,
                      child: AnimatedContainer(
                          key: key,
                          duration: Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                widget.shadowBorderRadius),
                            boxShadow: shadows,
                          ),
                          child: widget.child),
                    ),
                  ),
                ),
        ),
      )
    ]);
  }
}
