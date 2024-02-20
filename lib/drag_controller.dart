//

import 'package:drag_canvas/draggable_model.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class DragController<T extends DraggableModel> extends ChangeNotifier {
  final canvasKey = GlobalKey();
  Offset canvasOffset = Offset.zero;

  final List<T> children = [];

  final T Function() _create;

  final Widget Function(T) widgetBuilder;

  DragController(this._create, this.widgetBuilder);

  T create(Offset offset) {
    var newItem = this._create();
    newItem.offset = offset / scale;
    add(newItem);
    return newItem;
  }

  void sort() {
    Offset current = Offset.zero;
    for (final item in children) {
      item.offset = current;
      current += Offset(0, 75);
    }
    notifyListeners();
  }

  void add(T added) {
    children.add(added);
    notifyListeners();
  }

  void addAll(Iterable<T> added) {
    children.addAll(added);
    notifyListeners();
  }

  void reset() {
    children.clear();
  }

  ///
  /// Sets the offset for the entire canvas (i.e. translating all drawn elements by this Offset). This allows panning the canvas.
  ///
  void translateCanvas(Offset offset, {bool relativeToLast = true}) {
    print("Translating canvas");
    for (var item in children) {
      item.offset += offset;
    }
    canvasOffset += offset;
    notifyListeners();
  }

  double scale = 1;

  void setScale(double scaleDelta) {
    scale += scaleDelta;
    notifyListeners();
  }

  RenderBox getCanvasRenderBox() {
    return canvasKey.currentContext!.findRenderObject() as RenderBox;
  }
}
