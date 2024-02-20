import 'dart:math';

import 'package:drag_canvas/drag_controller.dart';
import 'package:drag_canvas/draggable_model.dart';
import 'package:drag_canvas/widgets/drag_canvas_widget.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _SomeDraggableModel extends DraggableModel {
  final String name;

  _SomeDraggableModel(this.name, DragController controller) : super(controller);
}

class _MyAppState extends State<MyApp> {
  late DragController<_SomeDraggableModel> _dragController;
  final _rnd = Random();

  @override
  void initState() {
    _dragController = DragController<_SomeDraggableModel>(() {
      return _SomeDraggableModel(DateTime.now().toString(), _dragController);
    }, (_SomeDraggableModel item) {
      return Container(color: Colors.red, child: Text(item.name));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            appBar: AppBar(
              title: const Text('Plugin example app'),
            ),
            floatingActionButton: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  _dragController.create(Offset(
                    _rnd.nextDouble() * 100,
                    _rnd.nextDouble() * 100,
                  ));
                }),
            body: DragCanvasWidget<_SomeDraggableModel>(
              controller: _dragController,
            )));
  }
}
