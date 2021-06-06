part of draggable_widget;

class DragController {
  bool disabled = false;
  late _DraggableWidgetState _widgetState;
  void _addState(_DraggableWidgetState _widgetState) {
    this._widgetState = _widgetState;
  }

  void disable() {
    disabled = true;
  }

  void enable() {
    disabled = false;
  }

  /// Jump to any [AnchoringPosition] programatically
  void jumpTo(AnchoringPosition anchoringPosition) {
    _widgetState._animateTo(anchoringPosition);
  }

  /// Get the current screen [Offset] of the widget
  Offset getCurrentPosition() {
    return _widgetState._currentOffset;
  }

  /// Makes the widget visible
  void showWidget() {
    _widgetState._showWidget();
  }

  /// Hide the widget
  void hideWidget() {
    _widgetState._hideWidget();
  }
}
