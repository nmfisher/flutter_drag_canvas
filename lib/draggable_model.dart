import 'package:drag_canvas/drag_controller.dart';

import 'package:drag_canvas/events/events.dart';
import 'package:drag_canvas/widgets/draggable_widget.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum Handle { Left, Right, Center }

class DraggableModel<T> {
  final DragController _dragController;

  DraggableModel(this._dragController);

  ///
  /// A key used to uniquely identify the DraggableWidget associated with this instance.
  /// This key is used to retrieve the widget's RenderBox when dragged/dropped/etc.
  ///
  final key = GlobalKey();

  ///
  /// The offset of the cursor when an item is being dragged.
  ///
  Offset _localCursorOffset = Offset.zero;

  List<DraggableModel<T>> _outboundEdges = [];

  Offset offset = Offset.zero;

  void connect(DraggableModel<T> to) {
    _outboundEdges.add(to);
  }

  void disconnect(DraggableModel<T> to) {
    _outboundEdges.remove(to);
  }

  void clearOutbound() {
    _outboundEdges.clear();
  }

  late RenderBox _canvasRb;

  void startDrag(Handle handle, DragHandleEvent event) {
    _canvasRb = _dragController.getCanvasRenderBox();
    var renderBox = (key.currentContext!.findRenderObject() as RenderBox);

    _localCursorOffset = renderBox.globalToLocal(event.globalPosition) -
        _dragController.canvasOffset;
  }

  void _calculatePaths() {
    // _paths = _outboundEdges
    //     .map((item) {
    //       var targetContext = item.key.currentContext;

    //       if (item.key.currentContext == null) {
    //         print("No current context");
    //         return null;
    //       }
    //       var canvasRb = (item.key.currentContext! as StatefulElement)
    //           .state
    //           .context
    //           .findAncestorRenderObjectOfType<RenderFlow>() as RenderBox;

    //       var outRb = (_keys[Handle.Right]!.currentContext!.findRenderObject()
    //           as RenderBox);
    //       var outTranslation =
    //           outRb.getTransformTo(context.findRenderObject()).getTranslation();
    //       var from = Offset(
    //           outTranslation.x + (outRb.size.width * widget.scale / 2),
    //           outTranslation.y + (outRb.size.height * widget.scale / 2));
    //       var targetState = (item.key.currentContext! as StatefulElement).state
    //           as _DraggableWidgetState;

    //       var inputHandleRb = targetState._keys[Handle.Left]!.currentContext!
    //           .findRenderObject() as RenderBox;

    //       var inputTx = inputHandleRb.getTransformTo(canvasRb)
    //         ..translate(inputHandleRb.size.width * widget.scale / 2,
    //             inputHandleRb.size.width * widget.scale / 2);
    //       var inputOffset =
    //           Offset(inputTx.getTranslation().x, inputTx.getTranslation().y);

    //       var to = (context.findRenderObject() as RenderBox)
    //           .globalToLocal(canvasRb.localToGlobal(inputOffset));
    //       return PathPainter(from, to, color: Color(0xFFCDCDCD));
    //     })
    //     .where((x) => x != null)
    //     .cast<PathPainter>()
    //     .toList();
  }

  void updateDrag(Handle handle, DragHandleEvent event) {
    var renderBox = (key.currentContext!.findRenderObject() as RenderBox);

    switch (handle) {
      case Handle.Center:
        // update the offset for the drag container
        var offset = _canvasRb
            .globalToLocal(event.globalPosition)
            .scale(1 / _dragController.scale, 1 / _dragController.scale);
        var newOffset =
            offset.translate(-_localCursorOffset.dx, -_localCursorOffset.dy);
        this.offset = newOffset.translate(
            -_dragController.canvasOffset.dx, -_dragController.canvasOffset.dy);
        _calculatePaths();
        break;
      default:
      // todo
    }
  }

  void onDrop(Handle handle, DragHandleEvent event) async {
    // var innerCtx = child.key.currentContext!;
    // var inputHandleKey =
    //     ((innerCtx as StatefulElement).state as _DraggableWidgetState)
    //         ._keys[Handle.Left]!;
    // var inputHandleRb =
    //     inputHandleKey.currentContext!.findRenderObject() as RenderBox;
    // var result = BoxHitTestResult();
    // var pos = inputHandleRb.globalToLocal(event.globalPosition);
    // if (inputHandleRb.hitTest(result, position: pos)) {
    //   connect(child);
    // }
  }

  void onEndDrag(DraggableModel item, Handle handle, DragHandleEvent event) {
    _localCursorOffset = Offset.zero;
  }

  bool hasInputConnection(DraggableModel model) {
    return _outboundEdges.contains(model);
  }

  // void disconnect(DraggableModel model) {
  //   for (var child in children) {
  //     child.item.disconnect(model);
  //   }
  //   notifyListeners();
  // }
}
