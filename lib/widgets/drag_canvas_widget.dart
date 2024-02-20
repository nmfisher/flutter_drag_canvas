import 'package:contextmenu/contextmenu.dart';
import 'package:drag_canvas/drag_controller.dart';
import 'package:drag_canvas/draggable_model.dart';
import 'package:drag_canvas/widgets/draggable_widget.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

//
// A surface for adding/dragging/dropping/etc widgets.
// This surface can also be zoomed in/out with the scroll button.
//
class DragCanvasWidget<T extends DraggableModel> extends StatefulWidget {
  final DragController<T> controller;

  DragCanvasWidget({required this.controller})
      : super(key: controller.canvasKey);

  @override
  State<StatefulWidget> createState() => _DragCanvasState<T>(controller);
}

class _DragCanvasState<T extends DraggableModel>
    extends State<DragCanvasWidget> {
  Offset _cursorPosition = Offset.zero;

  final DragController<T> _controller;

  _DragCanvasState(this._controller);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void didUpdateWidget(DragCanvasWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(
          child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  widget.controller.setScale(event.scrollDelta.dy / 200);
                }
              },
              onPointerDown: (PointerDownEvent event) {
                if (event.buttons == kSecondaryButton) {
                  _cursorPosition = event.position;
                  showContextMenu(
                      _cursorPosition,
                      context,
                      (ctx) => [
                            ListTile(
                              title: Text('New item'),
                              onTap: () {
                                var offset =
                                    (context.findRenderObject() as RenderBox)
                                        .globalToLocal(_cursorPosition);
                                widget.controller.create(offset);
                                Navigator.of(ctx).pop();
                              },
                            )
                          ],
                      0.0,
                      150.0);
                }
              },
              onPointerMove: (PointerMoveEvent event) {
                widget.controller.translateCanvas(event.delta);
              })),
      Positioned.fill(
          child: ListenableBuilder(
              listenable: _controller,
              builder: (_, __) => Flow(
                  delegate: DragCanvasDelegate(widget.controller),
                  children: _controller.children
                      .map((item) => DraggableWidget<T>(
                          onDragUpdate: () {
                            setState(() {});
                          },
                          item: item,
                          child: _controller.widgetBuilder(item)))
                      .cast<Widget>()
                      .toList()))),
      // Container(
      //     width: 150,
      //     child: Row(children: [
      //       IconButton(
      //         icon: Icon(Icons.sort),
      //         onPressed: () {
      //           widget.controller.sort();
      //         },
      //       )
      //     ]))
    ]);
    ;
  }
}

class DragCanvasDelegate extends FlowDelegate {
  final DragController controller;

  DragCanvasDelegate(this.controller);

  @override
  void paintChildren(FlowPaintingContext context) {
    for (int i = 0; i < context.childCount; i++) {
      context.paintChild(i,
          transform: Matrix4.identity()
            ..scale(controller.scale)
            ..translate(controller.children[i].offset.dx,
                controller.children[i].offset.dy));
    }
  }

  @override
  bool shouldRepaint(covariant FlowDelegate oldDelegate) {
    return true;
  }
}
