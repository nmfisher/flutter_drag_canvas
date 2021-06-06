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

  /// Initial location of the widget, default to [AnchoringPosition.bottomRight]
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
  final BoxShadow normalShadow;

  /// [BoxShadow] when the widget is being dragged
  ///```Dart
  ///const BoxShadow(
  ///     color: Colors.black38,
  ///    offset: Offset(0, 10),
  ///    blurRadius: 10,
  ///  ),
  /// ```
  final BoxShadow draggingShadow;

  /// Touch Delay Duration. Default value is zero. When set, drag operations will trigger after the duration.
  final Duration touchDelay;

  DraggableWidget({
    Key? key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.initialPosition = AnchoringPosition.bottomRight,
    this.initialVisibility = true,
    this.margin = EdgeInsets.zero,
    this.shadowBorderRadius = 10,
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
  RelativeRect _targetRect = RelativeRect.fill;

  ///
  /// A convenience getter to calculate the boundary Rect that surrounds the draggable widget;
  ///
  Size? containerSize;

  late AnimationController animationController;
  Animation<RelativeRect> animation =
      AlwaysStoppedAnimation<RelativeRect>(RelativeRect.fill);

  bool offstage = true;

  ///
  /// The last known anchor position of the draggable widget. This does not mean the widget is actually located at this position - it may have moved away under a drag gesture that's ongoing,
  /// or it may be moving towards this position after a drag was released.

  AnchoringPosition? anchorPosition;

  ///
  /// The height of the contents of the draggable widget. This is calculated.
  ///
  double widgetHeight = 18;
  double widgetWidth = 50;

  final key = GlobalKey();

  bool dragging = false;

  bool? visible;

  bool get currentVisibilty => visible ?? widget.initialVisibility;

  late bool isStillTouching;

  static Offset getOffsetForPosition(
      AnchoringPosition position, Rect item, Size containerSize) {
    Offset offset = Offset.zero;
    switch (position) {
      case AnchoringPosition.bottomRight:
        offset.translate(containerSize.width - item.width,
            containerSize.height - item.height);
        break;
      case AnchoringPosition.bottomLeft:
        offset.translate(0, containerSize.height - item.height);
        break;
      case AnchoringPosition.topRight:
        offset.translate(containerSize.width - item.width, 0);
        break;
      case AnchoringPosition.bottomCenter:
        offset.translate((containerSize.width - item.width) / 2,
            (containerSize.height - item.height) / 2);
        break;
      case AnchoringPosition.topCenter:
        offset.translate((containerSize.width - item.width) / 2, 0);
        break;
      default:
        throw Exception("Unrecognized offset");
    }
    return offset;
  }

  @override
  void initState() {
    anchorPosition = widget.initialPosition;
    animationController = AnimationController(
      value: 1,
      vsync: this,
      duration: Duration(milliseconds: 150),
    )
      ..addListener(() {})
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
      final widgetSize = getWidgetSize(key);
      if (widgetSize != null) {
        setState(() {
          widgetHeight = widgetSize.height;
          widgetWidth = widgetSize.width;
        });
      }

      await Future.delayed(Duration(
        milliseconds: 100,
      ));
      setState(() {
        offstage = false;
        _currentOffset = getOffsetForPosition(widget.initialPosition,
            Rect.fromLTWH(0, 0, widgetWidth, widgetHeight), containerSize!);
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DraggableWidget oldWidget) {
    if (offstage == false) {
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        final widgetSize = getWidgetSize(key);
        if (widgetSize != null) {
          setState(() {
            widgetHeight = widgetSize.height;
            widgetWidth = widgetSize.width;
          });
        }
      });
    }
    super.didUpdateWidget(oldWidget);
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

  void _setTargetOffsetFromPosition(AnchoringPosition target) {
    late Offset _targetOffset;
    switch (target) {
      case AnchoringPosition.topLeft:
        _targetOffset = Offset.zero;
        break;
      case AnchoringPosition.topRight:
        _targetOffset = Offset(containerSize!.width - widgetWidth, 0);
        break;
      case AnchoringPosition.bottomLeft:
        _targetOffset = Offset(0, containerSize!.height - widgetHeight);
        break;
      case AnchoringPosition.bottomRight:
        _targetOffset = Offset(containerSize!.width - widgetWidth,
            containerSize!.height - widgetHeight);
        break;
      case AnchoringPosition.center:
        _targetOffset = Offset((containerSize!.width - widgetWidth) / 2,
            (containerSize!.height - widgetHeight) / 2);
        break;
      case AnchoringPosition.topCenter:
        _targetOffset = Offset(containerSize!.width / 2, 0);
        break;
      case AnchoringPosition.bottomCenter:
        _targetOffset = Offset(
            containerSize!.width / 2, containerSize!.height - widgetHeight);
        break;
      default:
        throw Exception();
    }

    var begin =
        RelativeRect.fromLTRB(_currentOffset.dx, _currentOffset.dy, 0, 0);
    _targetRect =
        RelativeRect.fromLTRB(_targetOffset.dx, _targetOffset.dy, 0, 0);

    animation = RelativeRectTween(
      begin: begin,
      end: _targetRect,
    ).animate(CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    ));
  }

  Size? getWidgetSize(GlobalKey key) {
    final keyContext = key.currentContext;
    if (keyContext != null) {
      final box = keyContext.findRenderObject() as RenderBox;
      return box.size;
    } else {
      return null;
    }
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

  void _animateTo(AnchoringPosition position) async {
    if (animationController.isAnimating) {
      animationController.stop();
    }
    animationController.reset();
    _setTargetOffsetFromPosition(position);

    await animationController.forward();
    if (widget.onAnchor != null) widget.onAnchor!(position);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PositionedTransition(
        rect: animation,
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

                    _currentOffset = (context.findRenderObject() as RenderBox)
                        .globalToLocal(v.position);

                    anchorPosition = _calculateAnchorPosition(
                        _currentOffset.dx, _currentOffset.dy);

                    setState(() {
                      dragging = false;
                    });
                    _animateTo(anchorPosition!);
                  },
                  onPointerDown: (v) async {
                    if (widget.dragController?.disabled == true) return;
                    isStillTouching = false;
                    await Future.delayed(widget.touchDelay);
                    if (widget.onPointerDown != null) widget.onPointerDown!();
                    isStillTouching = true;
                  },
                  onPointerMove: (v) async {
                    if (!isStillTouching) {
                      return;
                    }
                    if (animationController.isAnimating) {
                      animationController.stop();
                      animationController.reset();
                    }
                    if (widget.onPointerMove != null) widget.onPointerMove!();

                    _currentOffset = (context.findRenderObject() as RenderBox)
                        .globalToLocal(v.position);
                    _currentOffset = Offset(
                        max(0, min(containerSize!.width - widgetWidth, _currentOffset.dx)),
                        max(0, min(containerSize!.height - widgetHeight, _currentOffset.dy)));
                        
                    animation = AlwaysStoppedAnimation<RelativeRect>(
                        RelativeRect.fromRect(
                            Rect.fromLTWH(_currentOffset.dx, _currentOffset.dy,
                                widgetWidth, widgetHeight),
                            Offset.zero & containerSize!));
                    setState(() {});

                  },
                  child: Offstage(
                    offstage: offstage,
                    child: Container(
                      color: Colors.red,
                      padding: widget.padding,
                      alignment: Alignment.topLeft,
                      child: AnimatedContainer(
                          key: key,
                          duration: Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                                widget.shadowBorderRadius),
                            boxShadow: [
                              dragging
                                  ? widget.draggingShadow
                                  : widget.normalShadow
                            ],
                          ),
                          child:
                              widget.child
                          ),
                    ),
                  ),
                ),
        ),
      )
    ]);
  }
}
