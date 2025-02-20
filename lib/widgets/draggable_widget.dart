import 'dart:async';

import 'package:drag_canvas/drag_controller.dart';
import 'package:drag_canvas/draggable_model.dart';
import 'package:drag_canvas/events/events.dart';
import 'package:flutter/material.dart';

//
// A widget that can be dragged/connected/etc.
// [item] is used to uniquely identify this widget, and must implement the methods on [DraggableModel].
//
final class DraggableWidget<T extends DraggableModel> extends StatefulWidget {
  final T item;
  final double scale;
  final Widget child;
  final void Function() onDragUpdate;
  final DragController<T> controller;

  DraggableWidget(
      {required this.item,
      this.scale = 1.0,
      required this.child,
      required this.onDragUpdate,
      required this.controller})
      : super(key: item.key);

  @override
  State<StatefulWidget> createState() => _DraggableWidgetState();
}

class _DraggableWidgetState extends State<DraggableWidget> {
  final List<StreamSubscription> _listeners = [];

  Map<Handle, bool> _dragging = {
    Handle.Left: false,
    Handle.Right: false,
    Handle.Center: false
  };

  List<PathPainter>? _paths = [];

  PathPainter? _dragPath;

  Map<Handle, GlobalKey> _keys = {
    Handle.Left: GlobalKey(),
    Handle.Right: GlobalKey(),
  };

  Map<Handle, bool> _highlight = {
    Handle.Left: false,
    Handle.Right: false,
    Handle.Center: false
  };

  void initState() {
    super.initState();
  }

  void dispose() {
    _listeners.forEach((listener) => listener.cancel());
    super.dispose();
  }

  void didUpdateWidget(DraggableWidget oldWidget) {
    setState(() {});
    super.didUpdateWidget(oldWidget);
  }

  void _recalculateDragPath(Handle loc, Offset globalCursorPosition) {
    var localCursorPosition = (context.findRenderObject() as RenderBox)
        .globalToLocal(globalCursorPosition);

    var handleRb =
        (_keys[loc]!.currentContext!.findRenderObject() as RenderBox);
    var translation =
        handleRb.getTransformTo(context.findRenderObject()).getTranslation();

    if (_dragPath != null) {
      _paths!.remove(_dragPath);
    }
    var from = Offset(translation.x + (handleRb.size.width * widget.scale / 2),
        translation.y + (handleRb.size.height * widget.scale / 2));

    _dragPath = PathPainter(from, localCursorPosition);
    _paths!.add(_dragPath!);

    setState(() {});
  }

  Widget _handle(Handle loc) {
    return Listener(
        key: _keys[loc],
        behavior: HitTestBehavior.opaque,
        onPointerDown: (v) {
          if (widget.controller.drawEdgeDisabled) {
            return;
          }
          switch (loc) {
            case Handle.Right:
              _dragging[loc] = true;
              widget.item.startDrag(loc, DragHandleEvent(v.position));
              break;
            case Handle.Left:
              if (widget.item.hasInputConnection(widget.item)) {
                widget.item.disconnect(widget.item);
              }
              break;
            default:
              break;
          }
        },
        onPointerMove: (v) {
          if (!_dragging[loc]!) {
            return;
          }
          widget.item.updateDrag(loc, DragHandleEvent(v.position));
          _recalculateDragPath(loc, v.position);
        },
        onPointerCancel: (v) {
          if (loc == Handle.Left) {
            _highlight[loc] = false;
          }
        },
        onPointerHover: (v) {
          if (_dragging[loc]!) {
            return;
          }
        },
        onPointerUp: (v) {
          if (_dragging[loc] != false) {
            widget.item.onDrop(loc, DragHandleEvent(v.position));
            if (_dragPath != null) {
              _paths!.remove(_dragPath);
            }
            _dragPath = null;
          }
          _recalculateDragPath(loc, v.position);

          _dragging[loc] = false;
          setState(() {});
        },
        child: Container(
            decoration: ShapeDecoration(
                shape: CircleBorder(), color: Colors.transparent),
            child: Container(height: 14, width: 14)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
        fit: StackFit.loose,
        clipBehavior: Clip.none,
        children: _paths!
                .map((path) => CustomPaint(
                      painter: path,
                      willChange: true,
                    ))
                .cast<Widget>()
                .toList() +
            [
              Container(
                  color: Colors.transparent,
                  child: Stack(
                      fit: StackFit.loose,
                      clipBehavior: Clip.none,
                      children: [
                        Listener(
                            // behavior: HitTestBehavior.opaque,
                            onPointerUp: (v) async {
                              _dragging[Handle.Center] = false;
                              widget.item.endDrag(
                                  Handle.Center, DragHandleEvent(v.position));
                            },
                            onPointerDown: (v) async {
                              widget.item.startDrag(
                                  Handle.Center, DragHandleEvent(v.position));
                              _dragging[Handle.Center] = true;
                            },
                            onPointerMove: (v) async {
                              widget.item.updateDrag(
                                  Handle.Center, DragHandleEvent(v.position));
                              widget.onDragUpdate();
                            },
                            child: widget.child),
                        // Positioned(
                        //     left: 0, top: 0, child: _handle(Handle.Left)),
                        // Positioned(
                        //     right: 0, top: 0, child: _handle(Handle.Right)),
                      ]))
            ]);
  }
}

class PathPainter extends CustomPainter {
  Offset from;
  Offset to;
  bool repaint = false;
  final Color color;

  PathPainter(this.from, this.to, {this.color = Colors.black});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(to.dx, to.dy),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return oldDelegate.from != from || oldDelegate.to != to;
  }
}
